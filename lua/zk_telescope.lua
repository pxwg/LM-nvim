local M = {}

-- Extract metadata from note file (comments at the beginning)
local function extract_metadata(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return {}
  end

  local lines = vim.fn.readfile(filepath)
  local metadata = {
    aliases = {},
    abstract = "",
    keywords = {},
  }

  -- Check if first line starts the metadata block
  if #lines == 0 or lines[1] ~= "/* Metadata:" then
    return metadata
  end

  -- Find metadata block end
  local metadata_end = nil
  for i = 1, #lines do
    if lines[i]:match("\\*/$") then
      metadata_end = i
      break
    end
  end

  if not metadata_end then
    return metadata
  end

  -- Extract and parse metadata line by line
  for i = 2, metadata_end - 1 do
    local line = lines[i]

    -- Parse aliases
    local aliases_str = line:match("^%s*Aliases:%s*(.*)$")
    if aliases_str and aliases_str ~= "" then
      for alias in aliases_str:gmatch("[^,]+") do
        local trimmed = alias:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" then
          table.insert(metadata.aliases, trimmed)
        end
      end
    end

    -- Parse abstract
    local abstract_str = line:match("^%s*Abstract:%s*(.*)$")
    if abstract_str and abstract_str ~= "" then
      metadata.abstract = abstract_str:gsub("^%s+", ""):gsub("%s+$", "")
    end

    -- Parse keywords
    local keywords_str = line:match("^%s*Keyword:%s*(.*)$")
    if keywords_str and keywords_str ~= "" then
      for keyword in keywords_str:gmatch("[^,]+") do
        local trimmed = keyword:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" then
          table.insert(metadata.keywords, trimmed)
        end
      end
    end
  end

  return metadata
end

-- Parse note file to extract title, tags, and metadata
local function parse_note(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return nil
  end

  local lines = vim.fn.readfile(filepath)
  local note_id = vim.fn.fnamemodify(filepath, ":t:r")

  -- Find the line with #import "../include.typ": *
  local import_idx = nil
  for i, line in ipairs(lines) do
    if line:match('#import%s+"%.%./include%.typ"%s*:%s*%*') then
      import_idx = i
      break
    end
  end

  if not import_idx then
    return nil
  end

  -- Title is on the first #show: zettel line + 2 (accounting for blank line)
  -- In the new format: import_idx is the import line, import_idx+1 is #show, import_idx+2 is blank, import_idx+3 is title
  local title = "Untitled"
  if #lines >= import_idx + 3 then
    local heading_line = lines[import_idx + 3]
    local match = heading_line:match("^=%s*(.-)%s*<")
    if match and match ~= "" then
      title = match
    else
      title = heading_line:gsub("^=%s*", "")
    end
  end

  -- Tags are on the line after title
  local tags = {}
  if #lines >= import_idx + 4 then
    local tag_line = lines[import_idx + 4]
    for tag in tag_line:gmatch("#tag%.([%w_]+)") do
      table.insert(tags, tag)
    end
  end

  -- Extract metadata (aliases, abstract, keywords)
  local metadata = extract_metadata(filepath)

  return {
    id = note_id,
    path = filepath,
    title = title,
    tags = tags,
    aliases = metadata.aliases,
    abstract = metadata.abstract,
    keywords = metadata.keywords,
  }
end

-- Get all notes
local function get_all_notes()
  local root = vim.fn.expand("~/wiki")
  local note_dir = root .. "/note"
  local notes = vim.fn.globpath(note_dir, "*.typ", false, true)

  local all_notes = {}
  for _, note_path in ipairs(notes) do
    local note = parse_note(note_path)
    if note then
      table.insert(all_notes, note)
    end
  end

  return all_notes
end

-- Create entry maker function for telescope picker
local function make_entry_factory(active_modes)
  return function(entry)
    local display_parts = { entry.title }

    -- Show aliases if alias mode is active
    if active_modes.alias and #entry.aliases > 0 then
      table.insert(display_parts, "(" .. table.concat(entry.aliases, ", ") .. ")")
    end

    -- Show abstract if abstract mode is active
    if active_modes.abstract and entry.abstract ~= "" then
      table.insert(display_parts, '"' .. entry.abstract .. '"')
    end

    -- Show keywords if keyword mode is active
    if active_modes.keyword and #entry.keywords > 0 then
      table.insert(display_parts, "{" .. table.concat(entry.keywords, ", ") .. "}")
    end

    local display = table.concat(display_parts, " ")

    -- Build ordinal based on active modes
    local ordinal_parts = { entry.id }

    if active_modes.title then
      table.insert(ordinal_parts, entry.title)
    end

    if active_modes.alias then
      table.insert(ordinal_parts, table.concat(entry.aliases, " "))
    end

    if active_modes.abstract then
      table.insert(ordinal_parts, entry.abstract)
    end

    if active_modes.keyword then
      table.insert(ordinal_parts, table.concat(entry.keywords, " "))
    end

    local ordinal = table.concat(ordinal_parts, " ")

    return {
      value = entry,
      display = display,
      ordinal = ordinal,
      filename = entry.path,
      lnum = 4,
      col = 1,
    }
  end
end

-- Main Telescope search function with multiple filter modes
function M.search_with_filters()
  local has_telescope, _ = pcall(require, "telescope.builtin")
  if not has_telescope then
    vim.notify("Telescope not found", vim.log.levels.ERROR)
    return
  end

  local all_notes = get_all_notes()

  if #all_notes == 0 then
    vim.notify("No notes found", vim.log.levels.INFO)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  -- Multiple modes can be active at once
  local active_modes = {
    title = true,
    alias = false,
    keyword = false,
    abstract = false,
  }
  local active_tag_filter = nil -- Selected tag filter
  local active_filters = {}
  local root = vim.fn.expand("~/wiki")

  local function get_mode_indicator()
    local modes = {}
    for mode, is_active in pairs(active_modes) do
      if is_active then
        table.insert(modes, string.upper(mode))
      end
    end
    local mode_str = #modes > 0 and table.concat(modes, "+") or "NONE"
    local filter_str = ""

    if active_tag_filter then
      filter_str = " [TAG: " .. active_tag_filter .. "]"
    end

    if #active_filters > 0 then
      if filter_str ~= "" then
        filter_str = filter_str .. " "
      end
      filter_str = filter_str .. "[FILTERS: " .. table.concat(active_filters, ", ") .. "]"
    end
    return mode_str .. filter_str
  end

  local function apply_filters(notes)
    local filtered = notes

    -- Apply tag filter first
    if active_tag_filter then
      local tag_filtered = {}
      for _, note in ipairs(filtered) do
        for _, tag in ipairs(note.tags) do
          if tag == active_tag_filter then
            table.insert(tag_filtered, note)
            break
          end
        end
      end
      filtered = tag_filtered
    end

    -- Apply keyword filters
    if #active_filters > 0 then
      local keyword_filtered = {}
      for _, note in ipairs(filtered) do
        local matches = true
        for _, filter in ipairs(active_filters) do
          -- Filter format: "keyword:value"
          local filter_type, filter_value = filter:match("([^:]+):(.+)")
          if filter_type == "keyword" then
            local has_keyword = false
            for _, keyword in ipairs(note.keywords) do
              if keyword:lower():match(filter_value:lower()) then
                has_keyword = true
                break
              end
            end
            matches = matches and has_keyword
          end
        end

        if matches then
          table.insert(keyword_filtered, note)
        end
      end
      filtered = keyword_filtered
    end

    return filtered
  end

  local function get_filtered_results()
    return apply_filters(all_notes)
  end

  local function open_picker(initial_notes)
    pickers
      .new({}, {
        prompt_title = "ZK Search [" .. get_mode_indicator() .. "]",
        finder = finders.new_table({
          results = initial_notes,
          entry_maker = make_entry_factory(active_modes),
        }),
        sorter = conf.generic_sorter({}),
        previewer = conf.file_previewer({}),
        attach_mappings = function(prompt_bufnr, map)
          -- Open selected note
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then
              vim.cmd("cd " .. vim.fn.fnameescape(root))
              vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
            end
          end)

          -- Toggle individual modes
          map("i", "<C-t>", function()
            active_modes.title = not active_modes.title
            actions.close(prompt_bufnr)
            open_picker(get_filtered_results())
          end)

          map("i", "<C-s>", function()
            active_modes.alias = not active_modes.alias
            actions.close(prompt_bufnr)
            open_picker(get_filtered_results())
          end)

          map("i", "<C-k>", function()
            active_modes.keyword = not active_modes.keyword
            actions.close(prompt_bufnr)
            open_picker(get_filtered_results())
          end)

          map("i", "<C-a>", function()
            active_modes.abstract = not active_modes.abstract
            actions.close(prompt_bufnr)
            open_picker(get_filtered_results())
          end)

          -- <C-g>: Select tag filter
          map("i", "<C-g>", function()
            actions.close(prompt_bufnr)

            -- Collect all tags from all notes
            local all_tags = {}
            for _, note in ipairs(all_notes) do
              for _, tag in ipairs(note.tags) do
                all_tags[tag] = true
              end
            end

            local tag_options = {}
            for tag, _ in pairs(all_tags) do
              table.insert(tag_options, tag)
            end

            if #tag_options == 0 then
              vim.notify("No tags available", vim.log.levels.INFO)
              open_picker(get_filtered_results())
              return
            end

            -- Display tag selection
            pickers
              .new({}, {
                prompt_title = "Select tag to filter",
                finder = finders.new_table({
                  results = tag_options,
                  entry_maker = function(tag)
                    return {
                      value = tag,
                      display = tag,
                      ordinal = tag,
                    }
                  end,
                }),
                sorter = conf.generic_sorter({}),
                attach_mappings = function(tag_prompt_bufnr, _tag_map)
                  actions.select_default:replace(function()
                    actions.close(tag_prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection then
                      active_tag_filter = selection.value
                    end
                    open_picker(get_filtered_results())
                  end)
                  return true
                end,
              })
              :find()
          end)

          -- <C-f>: Add keyword filter
          map("i", "<C-f>", function()
            actions.close(prompt_bufnr)

            -- Collect all keywords from all notes
            local filter_options = {}
            local all_keywords = {}
            for _, note in ipairs(all_notes) do
              for _, keyword in ipairs(note.keywords) do
                all_keywords[keyword] = true
              end
            end
            for keyword, _ in pairs(all_keywords) do
              table.insert(filter_options, keyword)
            end

            if #filter_options == 0 then
              vim.notify("No keywords available", vim.log.levels.INFO)
              open_picker(get_filtered_results())
              return
            end

            -- Display keyword selection
            pickers
              .new({}, {
                prompt_title = "Select keyword to filter",
                finder = finders.new_table({
                  results = filter_options,
                  entry_maker = function(keyword)
                    return {
                      value = keyword,
                      display = keyword,
                      ordinal = keyword,
                    }
                  end,
                }),
                sorter = conf.generic_sorter({}),
                attach_mappings = function(filter_prompt_bufnr, _filter_map)
                  actions.select_default:replace(function()
                    actions.close(filter_prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection then
                      local filter_str = "keyword:" .. selection.value
                      -- Check if filter already exists
                      local already_exists = false
                      for _, f in ipairs(active_filters) do
                        if f == filter_str then
                          already_exists = true
                          break
                        end
                      end

                      if not already_exists then
                        table.insert(active_filters, filter_str)
                      end
                    end
                    open_picker(get_filtered_results())
                  end)
                  return true
                end,
              })
              :find()
          end)

          -- <C-r>: Clear all filters
          map("i", "<C-r>", function()
            active_filters = {}
            active_tag_filter = nil
            actions.close(prompt_bufnr)
            open_picker(get_filtered_results())
          end)

          return true
        end,
      })
      :find()
  end

  open_picker(get_filtered_results())
end

-- Search by default mode (title)
function M.search_title()
  M.search_with_filters()
end

-- Search by alias
function M.search_alias()
  local has_telescope, _ = pcall(require, "telescope.builtin")
  if not has_telescope then
    vim.notify("Telescope not found", vim.log.levels.ERROR)
    return
  end

  local all_notes = get_all_notes()

  -- Filter notes that have aliases
  local notes_with_aliases = {}
  for _, note in ipairs(all_notes) do
    if #note.aliases > 0 then
      table.insert(notes_with_aliases, note)
    end
  end

  if #notes_with_aliases == 0 then
    vim.notify("No notes with aliases found", vim.log.levels.INFO)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local root = vim.fn.expand("~/wiki")

  pickers
    .new({}, {
      prompt_title = "ZK Search by Alias",
      finder = finders.new_table({
        results = notes_with_aliases,
        entry_maker = make_entry_factory("alias"),
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.file_previewer({}),
      attach_mappings = function(prompt_bufnr, _map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            vim.cmd("cd " .. vim.fn.fnameescape(root))
            vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
          end
        end)
        return true
      end,
    })
    :find()
end

-- Search by keywords
function M.search_keyword()
  local has_telescope, _ = pcall(require, "telescope.builtin")
  if not has_telescope then
    vim.notify("Telescope not found", vim.log.levels.ERROR)
    return
  end

  local all_notes = get_all_notes()

  -- Filter notes that have keywords
  local notes_with_keywords = {}
  for _, note in ipairs(all_notes) do
    if #note.keywords > 0 then
      table.insert(notes_with_keywords, note)
    end
  end

  if #notes_with_keywords == 0 then
    vim.notify("No notes with keywords found", vim.log.levels.INFO)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local root = vim.fn.expand("~/wiki")

  pickers
    .new({}, {
      prompt_title = "ZK Search by Keyword",
      finder = finders.new_table({
        results = notes_with_keywords,
        entry_maker = make_entry_factory("keyword"),
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.file_previewer({}),
      attach_mappings = function(prompt_bufnr, _map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            vim.cmd("cd " .. vim.fn.fnameescape(root))
            vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
          end
        end)
        return true
      end,
    })
    :find()
end

-- Search by abstract
function M.search_abstract()
  local has_telescope, _ = pcall(require, "telescope.builtin")
  if not has_telescope then
    vim.notify("Telescope not found", vim.log.levels.ERROR)
    return
  end

  local all_notes = get_all_notes()

  -- Filter notes that have abstract
  local notes_with_abstract = {}
  for _, note in ipairs(all_notes) do
    if note.abstract ~= "" then
      table.insert(notes_with_abstract, note)
    end
  end

  if #notes_with_abstract == 0 then
    vim.notify("No notes with abstract found", vim.log.levels.INFO)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local root = vim.fn.expand("~/wiki")

  pickers
    .new({}, {
      prompt_title = "ZK Search by Abstract",
      finder = finders.new_table({
        results = notes_with_abstract,
        entry_maker = make_entry_factory("abstract"),
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.file_previewer({}),
      attach_mappings = function(prompt_bufnr, _map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            vim.cmd("cd " .. vim.fn.fnameescape(root))
            vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
          end
        end)
        return true
      end,
    })
    :find()
end

return M
