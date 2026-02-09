local M = {}

-- Check if a node is inside a code block or raw block
local function is_in_code_block(node)
  local current = node
  while current do
    local node_type = current:type()
    -- Check for various code/raw block types in Typst
    if
      node_type == "raw_blck"
      or node_type == "code_block"
      or node_type == "raw"
      or node_type == "raw_block"
      or node_type == "code"
      or node_type:match("^raw_")
      or node_type:match("^code_")
    then
      return true
    end
    current = current:parent()
  end
  return false
end

-- Check if all todos are completed in the buffer (using Treesitter)
-- Returns: (has_todos, completed_count, incomplete_count)
local function check_todo_status()
  -- Try to use Treesitter if available
  local _, ts_parsers = pcall(require, "nvim-treesitter.parsers")
  local parser = ts_parsers.get_parser(0, "typst")
  local tree = parser:parse()[1]
  local root = tree:root()

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local completed_count = 0
  local incomplete_count = 0

  -- Iterate through all lines
  for line_num = 0, #lines - 1 do
    local line = lines[line_num + 1]

    -- Check if line matches todo pattern
    if line:match("^%s*%- %[.%]") then
      -- Get the node at this line
      local node = root:descendant_for_range(line_num, 0, line_num, #line)

      -- Skip if inside code block
      if node and not is_in_code_block(node) then
        -- Check if this todo is completed or not
        if line:match("^%s*%- %[x%]") or line:match("^%s*%- %[X%]") then
          completed_count = completed_count + 1
        else
          incomplete_count = incomplete_count + 1
        end
      end
    end
  end

  local has_todos = completed_count > 0 or incomplete_count > 0
  return has_todos, completed_count, incomplete_count
end

-- Fallback function without Treesitter
-- Returns: (has_todos, completed_count, incomplete_count)
local function check_todo_status_fallback()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local completed_count = 0
  local incomplete_count = 0
  local in_code_block = false

  for _, line in ipairs(lines) do
    -- Detect code block boundaries (``` or """)
    if line:match("^%s*```") or line:match('^%s*"""') then
      in_code_block = not in_code_block
    end

    -- Match any todo item pattern: - [ ] or - [x]
    if not in_code_block and line:match("^%s*%- %[.%]") then
      -- Check if this todo is completed or not
      if line:match("^%s*%- %[x%]") or line:match("^%s*%- %[X%]") then
        completed_count = completed_count + 1
      else
        incomplete_count = incomplete_count + 1
      end
    end
  end

  local has_todos = completed_count > 0 or incomplete_count > 0
  return has_todos, completed_count, incomplete_count
end

-- Auto-update tag based on todo completion status
function M.auto_update_tag()
  local filepath = vim.fn.expand("%:p")

  -- Only process .typ files in the note directory
  if not filepath:match("/note/%d+%.typ$") then
    return
  end

  local has_todos, completed_count, incomplete_count = check_todo_status()

  -- Only update if there are todos in the file
  if not has_todos then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Check line 5 (index 5 in Lua) for the tag
  if #lines < 5 then
    return
  end

  local tag_line = lines[5]
  local tag_line_idx = 4 -- 0-indexed for nvim_buf_set_lines

  -- Determine what the tag should be based on todo counts
  local new_tag = nil
  if incomplete_count == 0 and completed_count > 0 then
    -- All todos completed
    new_tag = "#tag.done"
  elseif completed_count > 0 and incomplete_count > 0 then
    -- Mixed state: some completed, some incomplete
    new_tag = "#tag.wip"
  else
    -- All todos incomplete
    new_tag = "#tag.todo"
  end

  -- Check current tag
  local current_tag = nil
  if tag_line:match("#tag%.done") then
    current_tag = "#tag.done"
  elseif tag_line:match("#tag%.wip") then
    current_tag = "#tag.wip"
  elseif tag_line:match("#tag%.todo") then
    current_tag = "#tag.todo"
  end

  -- Update if needed
  if new_tag and current_tag ~= new_tag then
    local new_line = tag_line
    if current_tag then
      new_line = tag_line:gsub(current_tag, new_tag)
    else
      -- No existing tag found, append the new tag
      new_line = tag_line .. " " .. new_tag
    end
    vim.api.nvim_buf_set_lines(0, tag_line_idx, tag_line_idx + 1, false, { new_line })

    local message = string.format(
      "Todo status updated: %d completed, %d incomplete. Tag updated to %s",
      completed_count,
      incomplete_count,
      new_tag
    )
    vim.notify(message, vim.log.levels.INFO)
  end
end

-- Toggle or create todo item
function M.toggle_todo()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

  if not line then
    return
  end

  -- Check if line already has a todo pattern
  local todo_pattern = "^(%s*)%- %[(.?)%](.*)$"
  local indent, state, rest = line:match(todo_pattern)

  if indent then
    -- Toggle between [ ] and [x]
    local new_state = (state == " ") and "x" or " "
    local new_line = indent .. "- [" .. new_state .. "]" .. rest
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })

    -- Auto-check and update tag after toggling
    vim.schedule(function()
      M.auto_update_tag()
    end)
  else
    -- Insert new todo item with proper indentation
    local indent_match = line:match("^(%s*)")
    local indent = indent_match or ""
    local new_line = indent .. "- [ ] "
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })

    vim.api.nvim_win_set_cursor(0, { row, #new_line + 1 })
  end
end

local function note_paths(id)
  local root = vim.fn.expand("~/wiki")
  local note_dir = root .. "/note"
  local note_path = note_dir .. "/" .. id .. ".typ"
  local index_path = root .. "/index.typ"
  return root, note_dir, note_path, index_path
end

function M.new_note()
  local id = os.date("%y%m%d%H%M")
  local root, note_dir, note_path, index_path = note_paths(id)

  vim.fn.mkdir(note_dir, "p")

  if vim.fn.filereadable(note_path) == 0 then
    local lines = {
      '#import "../include.typ": *',
      "#show: zettel",
      "",
      "=  <" .. id .. ">",
      "#tag.",
      "",
    }
    vim.fn.writefile(lines, note_path)
  end
  if vim.fn.filereadable(index_path) == 1 then
    local include_line = '#include "note/' .. id .. '.typ"'
    local index_lines = vim.fn.readfile(index_path)
    local exists = false
    for _, line in ipairs(index_lines) do
      if line == include_line then
        exists = true
        break
      end
    end
    if not exists then
      table.insert(index_lines, include_line)
      vim.fn.writefile(index_lines, index_path)
    end
  end

  vim.cmd("cd " .. vim.fn.fnameescape(root))
  vim.cmd("edit " .. vim.fn.fnameescape(note_path))

  local target_line = math.min(4, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_win_set_cursor(0, { target_line, 2 })
end

-- Get all note IDs referenced in a file
local function extract_note_ids(filepath)
  local ids = {}
  if vim.fn.filereadable(filepath) == 0 then
    return ids
  end

  local lines = vim.fn.readfile(filepath)
  for _, line in ipairs(lines) do
    -- Match patterns like @2602082135
    for id in line:gmatch("@(%d+)") do
      ids[id] = true
    end
  end
  return ids
end

-- Read note content without the first 3 lines (imports)
local function read_note_content(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return nil
  end

  local lines = vim.fn.readfile(filepath)
  -- Skip first 3 lines (#import, #show, empty line)
  local content = {}
  for i = 4, #lines do
    table.insert(content, lines[i])
  end
  return table.concat(content, "\n")
end

-- Recursively collect all linked notes with depth tracking
local function collect_linked_notes(start_id, visited, depth)
  visited = visited or {}
  depth = depth or 0

  -- Avoid circular references
  if visited[start_id] then
    return {}
  end
  visited[start_id] = true

  local root, note_dir, note_path, _ = note_paths(start_id)
  local result = {}

  -- Add current note
  local content = read_note_content(note_path)
  if content then
    -- First collect all referenced notes (they go before current note)
    local referenced_ids = extract_note_ids(note_path)
    for ref_id, _ in pairs(referenced_ids) do
      -- Recursively collect linked notes with increased depth
      local sub_notes = collect_linked_notes(ref_id, visited, depth + 1)
      for _, note in ipairs(sub_notes) do
        table.insert(result, note)
      end
    end
    -- Then add current note (so it comes after its dependencies)
    table.insert(result, {
      id = start_id,
      path = note_path,
      content = content,
      depth = depth,
    })
  end

  return result
end

-- Export current note and all linked notes for AI context
function M.export_for_ai()
  local current_file = vim.fn.expand("%:p")
  local current_id = vim.fn.expand("%:t:r")

  -- Validate it's a note file
  if not current_file:match("/note/%d+%.typ$") then
    vim.notify("Not a ZK note file", vim.log.levels.WARN)
    return
  end

  -- Collect all linked notes
  local notes = collect_linked_notes(current_id)

  if #notes == 0 then
    vim.notify("No notes found", vim.log.levels.WARN)
    return
  end

  -- Build the export content
  local export_lines = {
    "# ZK Notes Export for AI Context",
    "# Root Note: " .. current_id,
    "# Total Notes: " .. #notes,
    "",
    string.rep("=", 80),
    "",
  }
  for _, note in ipairs(notes) do
    table.insert(export_lines, "## Note: " .. note.id)
    table.insert(export_lines, "## Path: " .. note.path)
    table.insert(export_lines, "")
    -- Split content by newlines and add each line separately
    for line in note.content:gmatch("[^\n]*") do
      table.insert(export_lines, line)
    end
    table.insert(export_lines, "")
    table.insert(export_lines, string.rep("=", 80))
    table.insert(export_lines, "")
  end

  -- Create a new buffer with the export
  local export_text = table.concat(export_lines, "\n")

  -- Create a new scratch buffer
  vim.cmd("new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, export_lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_name(buf, "ZK Export: " .. current_id)

  -- Copy to clipboard
  vim.fn.setreg("+", export_text)

  vim.notify("Exported " .. #notes .. " notes to buffer and clipboard", vim.log.levels.INFO)
end

-- Search for notes with specific tags using Telescope
function M.search_by_tag(tag)
  local has_telescope, telescope = pcall(require, "telescope.builtin")
  if not has_telescope then
    vim.notify("Telescope not found", vim.log.levels.ERROR)
    return
  end

  local root = vim.fn.expand("~/wiki")
  local note_dir = root .. "/note"

  -- Get all .typ files in note directory
  local notes = vim.fn.globpath(note_dir, "*.typ", false, true)
  local results = {}

  for _, note_path in ipairs(notes) do
    if vim.fn.filereadable(note_path) == 1 then
      local lines = vim.fn.readfile(note_path)
      -- Check line 5 (index 5 in Lua) for the tag
      if #lines >= 5 then
        local tag_line = lines[5]
        if tag_line:match("#tag%." .. tag) then
          -- Extract title from line 4 (the heading)
          local title = "Untitled"
          if #lines >= 4 then
            local heading_line = lines[4]
            -- Match pattern like "= Title <id>"
            local match = heading_line:match("^=%s*(.-)%s*<")
            if match and match ~= "" then
              title = match
            else
              -- Fallback: just remove leading "= "
              title = heading_line:gsub("^=%s*", "")
            end
          end
          local note_id = vim.fn.fnamemodify(note_path, ":t:r")
          table.insert(results, {
            filename = note_path,
            lnum = 5,
            col = 1,
            text = title,
            id = note_id,
          })
        end
      end
    end
  end

  if #results == 0 then
    vim.notify("No notes found with tag: " .. tag, vim.log.levels.INFO)
    return
  end

  -- Use Telescope's quickfix list display
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = "Notes with #tag." .. tag,
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          return {
            value = entry,
            display = string.format("[%s] %s", entry.id, entry.text),
            ordinal = entry.text .. " " .. entry.id,
            filename = entry.filename,
            lnum = entry.lnum,
            col = entry.col,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.file_previewer({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          local root = vim.fn.expand("~/wiki")
          vim.cmd("cd " .. vim.fn.fnameescape(root))
          vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
        end)
        return true
      end,
    })
    :find()
end

-- Enhanced search with multi-mode support (title, combined title+tag filter)
function M.search_title()
  local has_telescope, _ = pcall(require, "telescope.builtin")
  if not has_telescope then
    vim.notify("Telescope not found", vim.log.levels.ERROR)
    return
  end

  local root = vim.fn.expand("~/wiki")
  local note_dir = root .. "/note"
  local notes = vim.fn.globpath(note_dir, "*.typ", false, true)
  local all_results = {}

  for _, note_path in ipairs(notes) do
    if vim.fn.filereadable(note_path) == 1 then
      local lines = vim.fn.readfile(note_path)
      local title = "Untitled"
      local tags = {}

      -- Extract title from line 4
      if #lines >= 4 then
        local heading_line = lines[4]
        local match = heading_line:match("^=%s*(.-)%s*<")
        if match and match ~= "" then
          title = match
        else
          title = heading_line:gsub("^=%s*", "")
        end
      end

      -- Extract tags from line 5
      if #lines >= 5 then
        local tag_line = lines[5]
        for tag in tag_line:gmatch("#tag%.([%w_]+)") do
          table.insert(tags, tag)
        end
      end

      local note_id = vim.fn.fnamemodify(note_path, ":t:r")
      table.insert(all_results, {
        filename = note_path,
        lnum = 4,
        col = 1,
        text = title,
        id = note_id,
        tags = tags,
      })
    end
  end

  if #all_results == 0 then
    vim.notify("No notes found", vim.log.levels.INFO)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  -- Search mode: "title" (default), "tag_filter"
  local search_mode = "title"
  local mode_indicator = "[TITLE]"
  local selected_tag = nil
  local tag_filter_indicator = ""

  local function get_filtered_results()
    if search_mode == "tag_filter" and selected_tag then
      local filtered = {}
      for _, result in ipairs(all_results) do
        for _, tag in ipairs(result.tags) do
          if tag == selected_tag then
            table.insert(filtered, result)
            break
          end
        end
      end
      return filtered
    end
    return all_results
  end

  local function make_entry(entry)
    local tag_display = #entry.tags > 0 and (" #" .. table.concat(entry.tags, " #")) or ""
    return {
      value = entry,
      display = string.format("[%s] %s%s", entry.id, entry.text, tag_display),
      ordinal = entry.text .. " " .. entry.id .. " " .. table.concat(entry.tags, " "),
      filename = entry.filename,
      lnum = entry.lnum,
      col = entry.col,
    }
  end

  local function refresh_picker(prompt_bufnr)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    if current_picker then
      local filtered_results = get_filtered_results()
      local new_finder = finders.new_table({
        results = filtered_results,
        entry_maker = make_entry,
      })
      current_picker:refresh(new_finder, { reset_prompt = false })
    end
  end

  local function update_title(prompt_bufnr)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    if current_picker then
      local title = "ZK Note Search " .. mode_indicator .. tag_filter_indicator
      current_picker.prompt_border:change_title(title)
    end
  end

  pickers
    .new({}, {
      prompt_title = "ZK Note Search " .. mode_indicator .. tag_filter_indicator,
      finder = finders.new_table({
        results = get_filtered_results(),
        entry_maker = make_entry,
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.file_previewer({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          vim.cmd("cd " .. vim.fn.fnameescape(root))
          vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
        end)

        -- Ctrl-t: enter tag filter mode - open new picker with tag selection
        map("i", "<C-t>", function()
          actions.close(prompt_bufnr)

          local all_tags = {}
          for _, result in ipairs(all_results) do
            for _, tag in ipairs(result.tags) do
              all_tags[tag] = true
            end
          end

          local tag_list = {}
          for tag, _ in pairs(all_tags) do
            table.insert(tag_list, tag)
          end
          table.sort(tag_list)

          if #tag_list == 0 then
            vim.notify("No tags found", vim.log.levels.INFO)
            return
          end

          -- Open a new picker for tag selection
          pickers
            .new({}, {
              prompt_title = "Select tag to filter",
              finder = finders.new_table({
                results = tag_list,
              }),
              sorter = conf.generic_sorter({}),
              attach_mappings = function(tag_prompt_bufnr, tag_map)
                actions.select_default:replace(function()
                  actions.close(tag_prompt_bufnr)
                  local tag_selection = action_state.get_selected_entry()
                  if tag_selection then
                    -- Reopen the main search with tag filter
                    selected_tag = tag_selection.value
                    search_mode = "tag_filter"
                    tag_filter_indicator = " (tag: " .. selected_tag .. ")"

                    pickers
                      .new({}, {
                        prompt_title = "ZK Note Search [TITLE]" .. tag_filter_indicator,
                        finder = finders.new_table({
                          results = get_filtered_results(),
                          entry_maker = make_entry,
                        }),
                        sorter = conf.generic_sorter({}),
                        previewer = conf.file_previewer({}),
                        attach_mappings = function(new_prompt_bufnr, new_map)
                          actions.select_default:replace(function()
                            actions.close(new_prompt_bufnr)
                            local selection = action_state.get_selected_entry()
                            vim.cmd("cd " .. vim.fn.fnameescape(root))
                            vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
                          end)

                          -- Ctrl-t: toggle tag filter off
                          new_map("i", "<C-t>", function()
                            actions.close(new_prompt_bufnr)
                            selected_tag = nil
                            search_mode = "title"
                            tag_filter_indicator = ""
                            M.search_title()
                          end)

                          -- Ctrl-c: clear filter and restart
                          new_map("i", "<C-c>", function()
                            actions.close(new_prompt_bufnr)
                            selected_tag = nil
                            search_mode = "title"
                            tag_filter_indicator = ""
                            M.search_title()
                          end)

                          return true
                        end,
                      })
                      :find()
                  end
                end)
                return true
              end,
            })
            :find()
        end)

        -- Ctrl-c: clear tag filter
        map("i", "<C-c>", function()
          selected_tag = nil
          search_mode = "title"
          mode_indicator = "[TITLE]"
          tag_filter_indicator = ""
          update_title(prompt_bufnr)
          refresh_picker(prompt_bufnr)
        end)

        return true
      end,
    })
    :find()
end

-- Search for TODO notes
function M.search_todo()
  M.search_by_tag("todo")
end

-- Search for DONE notes
function M.search_done()
  M.search_by_tag("done")
end

-- Search for any tag (interactive)
function M.search_tag_prompt()
  vim.ui.input({ prompt = "Enter tag name: " }, function(input)
    if input and input ~= "" then
      M.search_by_tag(input)
    end
  end)
end

-- Get all notes with specific tags and format for display
local function get_notes_by_tags(tags)
  local root = vim.fn.expand("~/wiki")
  local note_dir = root .. "/note"

  -- Get all .typ files in note directory
  local notes = vim.fn.globpath(note_dir, "*.typ", false, true)
  local results = {}

  for _, note_path in ipairs(notes) do
    if vim.fn.filereadable(note_path) == 1 then
      local lines = vim.fn.readfile(note_path)
      -- Check line 5 (index 5 in Lua) for the tag
      if #lines >= 5 then
        local tag_line = lines[5]
        for _, tag in ipairs(tags) do
          if tag_line:match("#tag%." .. tag) then
            -- Extract title from line 4 (the heading)
            local title = "Untitled"
            if #lines >= 4 then
              local heading_line = lines[4]
              -- Match pattern like "= Title <id>"
              local match = heading_line:match("^=%s*(.-)%s*<")
              if match and match ~= "" then
                title = match
              else
                -- Fallback: just remove leading "= "
                title = heading_line:gsub("^=%s*", "")
              end
            end
            local note_id = vim.fn.fnamemodify(note_path, ":t:r")
            table.insert(results, {
              title = title,
              id = note_id,
              tag = tag,
              path = note_path,
            })
            break
          end
        end
      end
    end
  end

  return results
end

-- Display TODO and WIP notes on startup
function M.show_startup_summary()
  local tags = { "todo", "wip" }
  local notes = get_notes_by_tags(tags)

  if #notes == 0 then
    return
  end

  -- Sort by tag (wip first, then todo)
  table.sort(notes, function(a, b)
    if a.tag ~= b.tag then
      return a.tag == "wip"
    end
    return a.id < b.id
  end)

  -- Format output
  local lines = {
    "# ZK Note Summary - Tasks to Complete",
  }

  local line_entries = {}
  local tag_line_indices = {}
  local current_tag = nil
  for i, note in ipairs(notes) do
    if note.tag ~= current_tag then
      current_tag = note.tag
      if current_tag == "wip" then
        table.insert(lines, "")
        table.insert(lines, "## Work In Progress:")
      else
        table.insert(lines, "")
        table.insert(lines, "## To Do:")
      end
      table.insert(lines, "")
      tag_line_indices[#lines + 1] = true -- mark the first note line for this tag
    end
    table.insert(lines, string.format("  • %s [%s]", note.title, note.id))
    line_entries[#lines] = note
  end

  -- Collect all tag section start lines (for jumping)
  local tag_jump_lines = {}
  for idx, _ in pairs(tag_line_indices) do
    table.insert(tag_jump_lines, idx)
  end
  table.sort(tag_jump_lines)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "markdown"

  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 6)
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "",
  })

  local function close_summary()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  local function open_selected_note()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line = cursor[1]
    local note = line_entries[line]
    if not note or not note.path then
      return
    end
    close_summary()
    vim.cmd("edit " .. vim.fn.fnameescape(note.path))
  end

  -- Tab to jump between note entries (• xxx [xxx] 行)
  local note_lines = {}
  for i, line in ipairs(lines) do
    if line:match("^%s*•") then
      table.insert(note_lines, i)
    end
  end

  local function jump_to_next_note()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line = cursor[1]
    if #note_lines == 0 then
      return
    end
    local next_idx = 1
    for i, l in ipairs(note_lines) do
      if l > line then
        next_idx = i
        break
      end
      if i == #note_lines then
        next_idx = 1
      end
    end
    vim.api.nvim_win_set_cursor(win, { note_lines[next_idx], 0 })
  end

  local function jump_to_prev_note()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line = cursor[1]
    if #note_lines == 0 then
      return
    end
    local prev_idx = #note_lines
    for i = #note_lines, 1, -1 do
      if note_lines[i] < line then
        prev_idx = i
        break
      end
      if i == 1 then
        prev_idx = #note_lines
      end
    end
    vim.api.nvim_win_set_cursor(win, { note_lines[prev_idx], 0 })
  end

  vim.keymap.set("n", "q", close_summary, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_summary, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<CR>", open_selected_note, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Tab>", jump_to_next_note, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<S-Tab>", jump_to_prev_note, { buffer = buf, nowait = true })
end

vim.api.nvim_create_user_command("Zk", function(opts)
  local arg = opts.args
  if arg == "new" then
    M.new_note()
  elseif arg == "export" then
    M.export_for_ai()
  elseif arg == "search" then
    M.search_title()
  elseif arg == "todo" then
    M.search_todo()
  elseif arg == "done" then
    M.search_done()
  elseif arg == "tag" then
    M.search_tag_prompt()
  elseif arg == "summary" then
    M.show_startup_summary()
  else
    vim.notify("Unknown Zk command: " .. arg, vim.log.levels.ERROR)
  end
end, {
  desc = "ZK note actions",
  nargs = 1,
  complete = function(arg_lead, _, _)
    local opts = { "new", "export", "search", "todo", "done", "tag", "summary" }
    return vim.tbl_filter(function(opt)
      return vim.startswith(opt, arg_lead)
    end, opts)
  end,
})

-- Auto-update tag on buffer write (save)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*/note/*.typ",
  callback = function()
    M.auto_update_tag()
  end,
  desc = "Auto-update ZK note tags based on todo completion status",
})

vim.keymap.set("n", "<C-t>", M.toggle_todo, { noremap = true, silent = true })
vim.keymap.set("n", "zn", M.new_note, { noremap = true, silent = false, desc = "[Z]ettel [N]ew" })
vim.keymap.set("n", "zs", M.search_title, { noremap = true, silent = false, desc = "[Z]ettel [S]earch" })
vim.keymap.set("n", "ze", M.export_for_ai, { noremap = true, silent = false, desc = "[Z]ettel [E]xport for AI" })
vim.keymap.set(
  "n",
  "zS",
  M.show_startup_summary,
  { noremap = true, silent = false, desc = "[Z]ettel [S]tartup Summary" }
)
vim.keymap.set("n", "zt", M.search_todo, { noremap = true, silent = false, desc = "[Z]ettel [T]ODO Search" })

require("zk_extmark").setup()

return M
