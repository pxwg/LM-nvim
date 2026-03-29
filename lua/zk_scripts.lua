local M = {}
local zk_cli = require("zk_cli")

-- Execute a workspace/executeCommand on zk-lsp, returns true if dispatched
local function execute_command_zk_lsp(cmd, args, callback)
  local clients = vim.lsp.get_clients({ name = "zk-lsp" })
  if #clients == 0 then
    return false
  end
  for _, client in ipairs(clients) do
    client:request("workspace/executeCommand", {
      command = cmd,
      arguments = args or {},
    }, function(err, result)
      if callback then
        callback(err, result)
      end
    end)
  end
  return true
end

-- Refreshing Tinymist LSP client to recognize new notes
local function refresh_tinymist()
  local clients = vim.lsp.get_clients({ name = "tinymist" })
  for _, client in ipairs(clients) do
    client.notify("workspace/didChangeWatchedFiles", {
      changes = {
        {
          uri = vim.uri_from_fname(vim.fn.expand("~/wiki/link.typ")),
          type = 3,
        },
      },
    })
  end
  print("Tinymist refreshed for new note.")
end

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

-- Helper function to find title and tag positions by scanning for the first heading
-- Heading format: "= Title <id>"
local function find_note_structure(lines)
  for i, line in ipairs(lines) do
    if line:match("^=%s+.+%s+<%d+>") then
      return {
        title_idx = i,
        tag_idx = i + 1,
      }
    end
  end
  return nil
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

-- Update referencing todos in other notes when this note's tag changes
local function update_referencing_todos(note_id, new_tag)
  local root = vim.fn.expand("~/wiki")
  local note_dir = root .. "/note"
  local notes = vim.fn.globpath(note_dir, "*.typ", false, true)
  local ref_pattern = "(@%s*" .. note_id .. "%s*)"

  for _, note_path in ipairs(notes) do
    if vim.fn.filereadable(note_path) == 1 then
      local lines = vim.fn.readfile(note_path)
      local changed = false
      for i, line in ipairs(lines) do
        -- Only update todo lines referencing this note
        if line:match("^%s*%- %[[ xX]%].*" .. ref_pattern) then
          local new_state = (new_tag == "#tag.done") and "x" or " "
          local new_line = line:gsub("^%s*%- %[[ xX]%]", "- [" .. new_state .. "]")
          if new_line ~= line then
            lines[i] = new_line
            changed = true
          end
        end
      end
      if changed then
        vim.fn.writefile(lines, note_path)
      end
    end
  end
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

  -- Find the structure (import, title, tag positions)
  local structure = find_note_structure(lines)
  if not structure then
    return
  end

  local tag_line_idx = structure.tag_idx - 1 -- Convert to 0-based for nvim_buf_set_lines
  if #lines < tag_line_idx + 1 then
    return
  end

  local tag_line = lines[structure.tag_idx] -- Use 1-based index
  -- Defensive: if tag_line is nil, abort
  if not tag_line then
    return
  end

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

  -- Check current tag and archived status
  local current_tag = nil
  local has_archived = tag_line:match("#tag%.archived")

  if tag_line:match("#tag%.done") then
    current_tag = "#tag.done"
  elseif tag_line:match("#tag%.wip") then
    current_tag = "#tag.wip"
  elseif tag_line:match("#tag%.todo") then
    current_tag = "#tag.todo"
  end

  -- If archived tag exists, treat incomplete todos as done
  if has_archived and new_tag ~= "#tag.done" then
    new_tag = "#tag.done"
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
    local note_id = vim.fn.expand("%:t:r")
    update_referencing_todos(note_id, new_tag)
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
    -- vim.schedule(function()
    --   M.auto_update_tag()
    -- end)
  else
    -- Insert new todo item with proper indentation
    local indent_match = line:match("^(%s*)")
    local indent = indent_match or ""
    local new_line = indent .. "- [ ] "
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })

    vim.api.nvim_win_set_cursor(0, { row, #new_line + 1 })
  end
end

local function extract_pdf_path(file_field)
  if not file_field or file_field == "" then
    return nil
  end

  for path in file_field:gmatch("([^;]+)") do
    local trimmed = path:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed:match("%.pdf$") then
      return trimmed
    end
  end

  return nil
end

local function extract_html_path(file_field)
  if not file_field or file_field == "" then
    return nil
  end

  for path in file_field:gmatch("([^;]+)") do
    local trimmed = path:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed:match("%.html$") or trimmed:match("%.htm$") then
      return trimmed
    end
  end

  return nil
end

local function find_bib_asset_for_key(bib_path, key)
  if vim.fn.filereadable(bib_path) == 0 then
    return nil
  end

  local lines = vim.fn.readfile(bib_path)
  local in_entry = false
  local entry_lines = {}

  for _, line in ipairs(lines) do
    if not in_entry then
      if line:match("^@%w+%s*{%s*" .. key .. "%s*,") then
        in_entry = true
        entry_lines = { line }
      end
    else
      table.insert(entry_lines, line)
      if line:match("^}%s*$") then
        local entry_text = table.concat(entry_lines, " ")
        local file_field = entry_text:match("file%s*=%s*{(.-)}") or entry_text:match('file%s*=%s*"(.-)"')
        local url_field = entry_text:match("url%s*=%s*{(.-)}") or entry_text:match('url%s*=%s*"(.-)"')
        return {
          pdf_path = extract_pdf_path(file_field),
          html_path = extract_html_path(file_field),
          url = url_field,
        }
      end
    end
  end

  return nil
end

local function find_citation_at_cursor(line, col)
  if not line then
    return nil
  end

  local cursor_col = (col or 0) + 1
  local search_start = 1
  local last_key
  local last_end

  while true do
    local start_idx, end_idx = line:find("@([%w_:%-]+)", search_start)
    if not start_idx then
      break
    end

    local key = line:sub(start_idx + 1, end_idx)

    if cursor_col >= start_idx and cursor_col <= end_idx then
      return key, end_idx
    end

    if cursor_col > end_idx then
      last_key = key
      last_end = end_idx
      search_start = end_idx + 1
    else
      break
    end
  end

  return last_key, last_end
end

function M.open_pdf_at_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

  if not line then
    vim.notify("No line under cursor", vim.log.levels.WARN)
    return
  end

  local cite_key, cite_end = find_citation_at_cursor(line, col)
  if not cite_key or not cite_end then
    vim.notify("No citation key found under cursor", vim.log.levels.WARN)
    return
  end

  local page = line:match("p%.?%s*(%d+)", cite_end + 1)

  local root = vim.fn.expand("~/wiki")
  local bib_path = root .. "/zotero-ref.bib"
  local assets = find_bib_asset_for_key(bib_path, cite_key)

  if not assets then
    vim.notify("No citation entry found for @" .. cite_key, vim.log.levels.WARN)
    return
  end

  if assets.pdf_path then
    local encoded_path = assets.pdf_path:gsub(" ", "%%20")
    local clear_path = "'" .. assets.pdf_path .. "'"
    local skim_url = clear_path
    if page then
      skim_url = "skim:///" .. encoded_path .. "#page=" .. page
      vim.fn.jobstart({ "open", skim_url }, { detach = true })
    end
    vim.fn.jobstart("open -a Skim " .. clear_path, { detach = true })
    return
  end

  local html_target = assets.url or assets.html_path
  if not html_target or html_target == "" then
    vim.notify("No PDF or HTML link found for @" .. cite_key, vim.log.levels.WARN)
    return
  end

  vim.fn.jobstart({ "open", html_target }, { detach = true })
end

local function note_paths(id)
  local root = vim.fn.expand("~/wiki")
  local note_dir = root .. "/note"
  local note_path = note_dir .. "/" .. id .. ".typ"
  local index_path = root .. "/index.typ"
  return root, note_dir, note_path, index_path
end

function M.new_note(with_metadata)
  local note_path = vim.fn.system({ "zk-lsp", "new", "--wiki-root", "./" })
  vim.cmd("edit " .. note_path)

  vim.schedule(function()
    -- Jump to the first "= Title <id>" heading line
    local line = vim.fn.search([[^= \S.\{-} <\d\+>]], "nw")
    if line > 0 then
      vim.api.nvim_win_set_cursor(0, { line, 2 })
    end
  end)

  refresh_tinymist()
end

-- Create note with metadata template
function M.new_note_with_metadata()
  M.new_note(true)
end

-- Create note without metadata (default)
function M.new_note_simple()
  M.new_note(false)
end

-- Remove a note and update index.typ accordingly
function M.remove_note(note_id)
  vim.fn.system({ "zk-lsp", "remove", note_id })
  refresh_tinymist()
end

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

-- Check if a note is marked as root
local function is_root_note(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return false
  end
  local lines = vim.fn.readfile(filepath)
  local structure = find_note_structure(lines)
  if not structure then
    return false
  end
  local tag_line = lines[structure.tag_idx]
  return tag_line ~= nil and tag_line:match("#tag%.root") ~= nil
end

-- Read note content starting from the title line (skipping preamble)
local function read_note_content(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return nil
  end

  local lines = vim.fn.readfile(filepath)
  local structure = find_note_structure(lines)
  local start = structure and structure.title_idx or 1
  local content = {}
  for i = start, #lines do
    table.insert(content, lines[i])
  end
  return table.concat(content, "\n")
end

-- Recursively collect all linked notes with depth tracking
-- Stops recursion at root notes (doesn't traverse beyond them)
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
    -- Check if this note is a root node
    local is_root = is_root_note(note_path)

    -- First collect all referenced notes (they go before current note)
    -- But only if this is NOT a root node (root nodes don't traverse backward)
    if not is_root then
      local referenced_ids = extract_note_ids(note_path)
      for ref_id, _ in pairs(referenced_ids) do
        -- Recursively collect linked notes with increased depth
        local sub_notes = collect_linked_notes(ref_id, visited, depth + 1)
        for _, note in ipairs(sub_notes) do
          table.insert(result, note)
        end
      end
    end

    -- Then add current note (so it comes after its dependencies)
    table.insert(result, {
      id = start_id,
      path = note_path,
      content = content,
      depth = depth,
      is_root = is_root,
    })
  end

  return result
end

local function open_recent_note_after_remove(removed_path)
  local note_dir = vim.fn.expand("~/wiki/note")
  local note_prefix = vim.fn.fnamemodify(note_dir, ":p")

  for _, oldfile in ipairs(vim.v.oldfiles or {}) do
    local file = vim.fn.fnamemodify(oldfile, ":p")
    if
      file ~= removed_path
      and file:match("^" .. vim.pesc(note_prefix) .. ".-%.typ$")
      and vim.fn.filereadable(file) == 1
    then
      vim.cmd("edit " .. vim.fn.fnameescape(file))
      return true
    end
  end

  return false
end

-- Open export text in a scratch buffer and copy to clipboard
local function open_export_buffer(export_text, note_id)
  local export_lines = vim.split(export_text, "\n", { plain = true })
  vim.cmd("new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, export_lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_name(buf, "ZK Export: " .. note_id)
  vim.fn.setreg("+", export_text)
end

-- Export current note context via zk-lsp (zk.exportContext), with Lua fallback
function M.export_for_ai()
  local current_file = vim.fn.expand("%:p")
  local current_id = vim.fn.expand("%:t:r")

  if not current_file:match("/note/%d+%.typ$") then
    vim.notify("Not a ZK note file", vim.log.levels.WARN)
    return
  end

  -- Try zk-lsp first
  local dispatched = execute_command_zk_lsp("zk.exportContext", { current_id, 5, true }, function(err, result)
    if err then
      vim.notify("zk-lsp exportContext error: " .. vim.inspect(err), vim.log.levels.WARN)
      return
    end
    if type(result) == "string" and result ~= "" then
      vim.schedule(function()
        open_export_buffer(result, current_id)
        vim.notify("Exported context via zk-lsp to buffer and clipboard", vim.log.levels.INFO)
      end)
    else
      vim.schedule(function()
        vim.notify("zk-lsp returned no content, falling back to Lua export", vim.log.levels.INFO)
        M._export_for_ai_fallback(current_id)
      end)
    end
  end)

  if not dispatched then
    M._export_for_ai_fallback(current_id)
  end
end

-- Lua fallback export (used when zk-lsp is not available)
function M._export_for_ai_fallback(current_id)
  local notes = collect_linked_notes(current_id)

  if #notes == 0 then
    vim.notify("No notes found", vim.log.levels.WARN)
    return
  end

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
    for line in note.content:gmatch("[^\n]*") do
      table.insert(export_lines, line)
    end
    table.insert(export_lines, "")
    table.insert(export_lines, string.rep("=", 80))
    table.insert(export_lines, "")
  end

  local export_text = table.concat(export_lines, "\n")
  open_export_buffer(export_text, current_id)
  vim.notify("Exported " .. #notes .. " notes to buffer and clipboard (Lua fallback)", vim.log.levels.INFO)
end

-- Search for notes with specific tags using Snacks.picker
function M.search_by_tag(tag)
  local root = vim.fn.expand("~/wiki")
  local results = {}

  for _, note in ipairs(zk_cli.list_notes({ include_references = true })) do
    if vim.tbl_contains(note.tags, tag) then
      table.insert(results, {
        filename = note.path,
        lnum = note.title_line,
        text = note.title,
        id = note.id,
      })
    end
  end

  if #results == 0 then
    vim.notify("No notes found with tag: " .. tag, vim.log.levels.INFO)
    return
  end

  local items = vim.tbl_map(function(entry)
    return {
      text = "[" .. entry.id .. "] " .. entry.text,
      file = entry.filename,
      pos = { entry.lnum, 0 },
    }
  end, results)

  Snacks.picker.pick({
    title = "Notes with #tag." .. tag,
    items = items,
    confirm = function(picker, item)
      picker:close()
      if item then
        local wiki_root = vim.fn.expand("~/wiki")
        vim.cmd("cd " .. vim.fn.fnameescape(wiki_root))
        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
      end
    end,
  })
end

-- Enhanced search with multi-mode support using zk_telescope module
-- Supports title, alias, keyword, abstract, and tag search modes
function M.search_title()
  local zk_telescope = require("zk_telescope")
  zk_telescope.search_with_filters()
end

-- Search for TODO notes
function M.search_todo()
  M.search_by_tag("todo")
end

-- Search for DONE notes
function M.search_done()
  M.search_by_tag("done")
end

-- Open a random note from ~/wiki/note/
function M.random_note()
  local root = vim.fn.expand("~/wiki")
  local note_dir = root .. "/note"
  local notes = vim.fn.globpath(note_dir, "*.typ", false, true)
  if #notes == 0 then
    vim.notify("No notes found!", vim.log.levels.INFO)
    return
  end
  local idx = math.random(1, #notes)
  vim.cmd("cd " .. vim.fn.fnameescape(root))
  vim.cmd("edit " .. vim.fn.fnameescape(notes[idx]))
end

-- Identify notes that are not referenced by any OTHER note
-- (References in index.typ are ignored, self-references are ignored)
function M.find_orphans()
  local all_notes = {} -- Map: id -> { path, title }
  local referenced_ids = {} -- Set: id -> true

  for _, note in ipairs(zk_cli.list_notes()) do
    all_notes[note.id] = {
      id = note.id,
      path = note.path,
      title = note.title,
      title_line = note.title_line,
    }

    for target_id, _ in pairs(note.references or {}) do
      if target_id ~= note.id then
        referenced_ids[target_id] = true
      end
    end
  end

  -- 3. Filter for orphans (Exists in all_notes but NOT in referenced_ids)
  local orphans = {}
  for id, note in pairs(all_notes) do
    if not referenced_ids[id] then
      table.insert(orphans, note)
    end
  end

  -- Sort by ID (time) descending
  table.sort(orphans, function(a, b)
    return a.id > b.id
  end)

  return orphans
end

-- Snacks.picker for Orphan Notes
function M.search_orphans()
  local orphans = M.find_orphans()
  if #orphans == 0 then
    vim.notify("No orphan notes found! Good job linking!", vim.log.levels.INFO)
    return
  end

  local root = vim.fn.expand("~/wiki")

  local items = vim.tbl_map(function(entry)
    return {
      text = "[" .. entry.id .. "] " .. entry.title,
      file = entry.path,
      pos = { entry.title_line or 1, 0 },
    }
  end, orphans)

  Snacks.picker.pick({
    title = "ZK Orphan Notes (" .. #orphans .. ")",
    items = items,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd("cd " .. vim.fn.fnameescape(root))
        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
      end
    end,
  })
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
  local results = {}

  for _, note in ipairs(zk_cli.list_notes()) do
    for _, tag in ipairs(tags) do
      if vim.tbl_contains(note.tags, tag) then
        table.insert(results, {
          title = note.title,
          id = note.id,
          tag = tag,
          path = note.path,
          title_line = note.title_line,
        })
        break
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
    M.new_note(false) -- Default: no metadata
  elseif arg == "newm" or arg == "new-metadata" then
    M.new_note_with_metadata()
  elseif arg == "export" then
    M.export_for_ai()
  elseif arg == "search" then
    M.search_title()
  elseif arg == "alias" then
    local zk_telescope = require("zk_telescope")
    zk_telescope.search_alias()
  elseif arg == "keyword" then
    local zk_telescope = require("zk_telescope")
    zk_telescope.search_keyword()
  elseif arg == "abstract" then
    local zk_telescope = require("zk_telescope")
    zk_telescope.search_abstract()
  elseif arg == "todo" then
    M.search_todo()
  elseif arg == "done" then
    M.search_done()
  elseif arg == "orphans" then
    M.search_orphans()
  elseif arg == "tag" then
    M.search_tag_prompt()
  elseif arg == "summary" then
    M.show_startup_summary()
  elseif arg == "random" then
    M.random_note()
  else
    vim.notify("Unknown Zk command: " .. arg, vim.log.levels.ERROR)
  end
end, {
  desc = "ZK note actions",
  nargs = 1,
  complete = function(arg_lead, _, _)
    local opts = {
      "new",
      "newm",
      "new-metadata",
      "export",
      "search",
      "alias",
      "keyword",
      "abstract",
      "todo",
      "done",
      "orphans",
      "tag",
      "summary",
      "random",
    }
    return vim.tbl_filter(function(opt)
      return vim.startswith(opt, arg_lead)
    end, opts)
  end,
})

-- Auto-update tag on buffer write (save)
-- vim.api.nvim_create_autocmd("BufWritePre", {
--   pattern = "*/note/*.typ",
--   callback = function()
--     M.auto_update_tag()
--   end,
--   desc = "Auto-update ZK note tags based on todo completion status",
-- })

vim.keymap.set("n", "<C-t>", M.toggle_todo, { noremap = true, silent = true })
vim.keymap.set(
  "n",
  "zn",
  M.new_note_with_metadata,
  { noremap = true, silent = false, desc = "[Z]ettel [N]ew with [M]etadata" }
)
vim.keymap.set("n", "zs", M.search_title, { noremap = true, silent = false, desc = "[Z]ettel [S]earch" })
vim.keymap.set("n", "<leader>fz", M.search_title, { noremap = true, silent = false, desc = "[F]ind [Z]ettel" })
vim.keymap.set("n", "ze", M.export_for_ai, { noremap = true, silent = false, desc = "[Z]ettel [E]xport for AI" })
vim.keymap.set(
  "n",
  "zS",
  M.show_startup_summary,
  { noremap = true, silent = false, desc = "[Z]ettel [S]tartup Summary" }
)
vim.keymap.set("n", "zt", M.search_todo, { noremap = true, silent = false, desc = "[Z]ettel [T]ODO Search" })
vim.keymap.set(
  "n",
  "<leader>zo",
  M.open_pdf_at_cursor,
  { noremap = true, silent = false, desc = "[Z]ettel [O]pen PDF at page" }
)
vim.keymap.set(
  "n",
  "<leader>fo",
  M.search_orphans,
  { noremap = true, silent = false, desc = "[F]ind [O]rphan Zettels" }
)
vim.keymap.set("n", "zr", function()
  local note_id = vim.fn.expand("<cword>")
  if note_id and note_id:match("^%d+$") then
    vim.ui.select({ "Yes", "No" }, { prompt = "Remove note " .. note_id .. "?" }, function(choice)
      if choice == "Yes" then
        local bufnr = vim.api.nvim_get_current_buf()
        local removed_path = vim.api.nvim_buf_get_name(bufnr)

        M.remove_note(note_id)
        vim.notify("Note " .. note_id .. " removed.", vim.log.levels.INFO)

        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end

        local jumped = open_recent_note_after_remove(removed_path)
        if not jumped then
          local root = vim.fn.expand("~/wiki")
          local index_path = root .. "/index.typ"
          vim.cmd("edit " .. vim.fn.fnameescape(index_path))
        end

        -- vim.schedule(function()
        --   M.show_startup_summary()
        -- end)
      else
        vim.notify("Aborted removing note " .. note_id .. ".", vim.log.levels.INFO)
      end
    end)
  else
    vim.notify("No valid note id under cursor.", vim.log.levels.WARN)
  end
end, { noremap = true, silent = false, desc = "[Z]ettel [R]emove" })

vim.keymap.set("n", "zR", function()
  local note_id = vim.api.nvim_buf_get_name(0):match("note/(%d+)%.typ$")
  if note_id and note_id:match("^%d+$") then
    vim.ui.select({ "Yes", "No" }, { prompt = "Remove note " .. note_id .. "?" }, function(choice)
      if choice == "Yes" then
        local bufnr = vim.api.nvim_get_current_buf()
        local removed_path = vim.api.nvim_buf_get_name(bufnr)

        M.remove_note(note_id)
        vim.notify("Note " .. note_id .. " removed.", vim.log.levels.INFO)

        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end

        local jumped = open_recent_note_after_remove(removed_path)
        if not jumped then
          local root = vim.fn.expand("~/wiki")
          local index_path = root .. "/index.typ"
          vim.cmd("edit " .. vim.fn.fnameescape(index_path))
        end

        -- vim.schedule(function()
        --   M.show_startup_summary()
        -- end)
      else
        vim.notify("Aborted removing note " .. note_id .. ".", vim.log.levels.INFO)
      end
    end)
  else
    vim.notify("No valid note id under cursor.", vim.log.levels.WARN)
  end
end, { noremap = true, silent = false, desc = "[Z]ettel [R]emove (Buffer)" })

require("zk_extmark").setup()

return M
