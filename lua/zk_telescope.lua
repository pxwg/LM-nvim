local M = {}
local function get_all_notes()
  return require("zk_cli").list_notes()
end

-- Build picker items from notes for the given active_modes
local function make_items(notes, active_modes)
  local n = #notes
  local items = {}
  for i, note in ipairs(notes) do
    local ordinal_parts = {}
    if active_modes.title then
      table.insert(ordinal_parts, note.title)
    end
    if active_modes.alias then
      table.insert(ordinal_parts, table.concat(note.aliases, " "))
    end
    if active_modes.abstract then
      -- Truncate to first 200 chars to avoid over-matching on long abstracts
      table.insert(ordinal_parts, note.abstract:sub(1, 200))
    end
    if active_modes.keyword then
      table.insert(ordinal_parts, table.concat(note.keywords, " "))
    end
    -- Fallback: always include title so items remain searchable
    if #ordinal_parts == 0 then
      table.insert(ordinal_parts, note.title)
    end
    -- Recency bonus: newer notes (earlier in desc-sorted list) get a higher score_add.
    -- Range 0–20, small enough not to dominate fuzzy score but meaningful as a tiebreaker.
    local recency_bonus = n > 1 and (n - i) / (n - 1) * 20 or 20
    table.insert(items, {
      text = table.concat(ordinal_parts, " "),
      -- Expose individual fields for targeted search: type "title:foo", "keyword:bar", etc.
      title = note.title,
      alias = #note.aliases > 0 and table.concat(note.aliases, " ") or nil,
      keyword = #note.keywords > 0 and table.concat(note.keywords, " ") or nil,
      abstract = note.abstract ~= "" and note.abstract or nil,
      file = note.path,
      pos = { note.title_line, 0 },
      _note = note,
      score_add = recency_bonus,
    })
  end
  return items
end

-- Build display highlight list for a note item given active modes
local function format_note_item(item, active_modes)
  local note = item._note
  local ret = {}
  ret[#ret + 1] = { "󰈙 ", "SnacksPickerIcon", virtual = true }
  ret[#ret + 1] = { note.title, "SnacksPickerFile" }
  if active_modes.alias and #note.aliases > 0 then
    ret[#ret + 1] = { "  ", virtual = true }
    ret[#ret + 1] = { table.concat(note.aliases, ", "), "SnacksPickerDimmed" }
  end
  if active_modes.abstract and note.abstract ~= "" then
    ret[#ret + 1] = { "  ", virtual = true }
    local abs = note.abstract:sub(1, 60) .. (note.abstract:len() > 60 and "…" or "")
    ret[#ret + 1] = { abs, "SnacksPickerComment" }
  end
  if active_modes.keyword and #note.keywords > 0 then
    ret[#ret + 1] = { "  ", virtual = true }
    for i, kw in ipairs(note.keywords) do
      if i > 1 then
        ret[#ret + 1] = { " ", virtual = true }
      end
      ret[#ret + 1] = { "[" .. kw .. "]", "SnacksPickerSpecial" }
    end
  end
  return ret
end

-- Main Snacks picker search with multiple filter modes
function M.search_with_filters()
  local all_notes = get_all_notes()

  if #all_notes == 0 then
    vim.notify("No notes found", vim.log.levels.INFO)
    return
  end

  local active_modes = {
    title = true,
    alias = false,
    keyword = false,
    abstract = false,
  }
  local active_tag_filter = nil
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

    if #active_filters > 0 then
      local keyword_filtered = {}
      for _, note in ipairs(filtered) do
        local matches = true
        for _, filter in ipairs(active_filters) do
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

  local function open_picker(notes)
    Snacks.picker.pick({
      title = "ZK Search [" .. get_mode_indicator() .. "]",
      items = make_items(notes, active_modes),
      format = function(item)
        return format_note_item(item, active_modes)
      end,
      confirm = function(picker, item)
        picker:close()
        if item then
          vim.cmd("cd " .. vim.fn.fnameescape(root))
          vim.cmd("edit " .. vim.fn.fnameescape(item.file))
        end
      end,
      win = {
        input = {
          keys = {
            ["<C-t>"] = { "toggle_title", mode = { "n", "i" } },
            ["<C-s>"] = { "toggle_alias", mode = { "n", "i" } },
            ["<C-k>"] = { "toggle_keyword", mode = { "n", "i" } },
            ["<C-a>"] = { "toggle_abstract", mode = { "n", "i" } },
            ["<C-g>"] = { "select_tag", mode = { "n", "i" } },
            ["<C-f>"] = { "select_keyword_filter", mode = { "n", "i" } },
            ["<C-r>"] = { "clear_filters", mode = { "n", "i" } },
          },
        },
      },
      actions = {
        toggle_title = function(picker)
          active_modes.title = not active_modes.title
          picker:close()
          open_picker(get_filtered_results())
        end,
        toggle_alias = function(picker)
          active_modes.alias = not active_modes.alias
          picker:close()
          open_picker(get_filtered_results())
        end,
        toggle_keyword = function(picker)
          active_modes.keyword = not active_modes.keyword
          picker:close()
          open_picker(get_filtered_results())
        end,
        toggle_abstract = function(picker)
          active_modes.abstract = not active_modes.abstract
          picker:close()
          open_picker(get_filtered_results())
        end,
        select_tag = function(picker)
          picker:close()
          local all_tags = {}
          for _, note in ipairs(all_notes) do
            for _, tag in ipairs(note.tags) do
              all_tags[tag] = true
            end
          end
          local tag_options = {}
          for tag, _ in pairs(all_tags) do
            table.insert(tag_options, { text = tag })
          end
          if #tag_options == 0 then
            vim.notify("No tags available", vim.log.levels.INFO)
            open_picker(get_filtered_results())
            return
          end
          Snacks.picker.pick({
            title = "Select tag to filter",
            layout = "select",
            items = tag_options,
            format = function(item)
              return { { item.text, "SnacksPickerFile" } }
            end,
            confirm = function(sub_picker, item)
              sub_picker:close()
              if item then
                active_tag_filter = item.text
              end
              open_picker(get_filtered_results())
            end,
          })
        end,
        select_keyword_filter = function(picker)
          picker:close()
          local all_keywords = {}
          for _, note in ipairs(all_notes) do
            for _, keyword in ipairs(note.keywords) do
              all_keywords[keyword] = true
            end
          end
          local filter_options = {}
          for keyword, _ in pairs(all_keywords) do
            table.insert(filter_options, { text = keyword })
          end
          if #filter_options == 0 then
            vim.notify("No keywords available", vim.log.levels.INFO)
            open_picker(get_filtered_results())
            return
          end
          Snacks.picker.pick({
            title = "Select keyword to filter",
            layout = "select",
            items = filter_options,
            format = function(item)
              return { { item.text, "SnacksPickerFile" } }
            end,
            confirm = function(sub_picker, item)
              sub_picker:close()
              if item then
                local filter_str = "keyword:" .. item.text
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
            end,
          })
        end,
        clear_filters = function(picker)
          active_filters = {}
          active_tag_filter = nil
          picker:close()
          open_picker(get_filtered_results())
        end,
      },
    })
  end

  open_picker(get_filtered_results())
end

-- Search by default mode (title)
function M.search_title()
  M.search_with_filters()
end

-- Search by alias
function M.search_alias()
  local all_notes = get_all_notes()
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

  local root = vim.fn.expand("~/wiki")
  local active_modes = { title = false, alias = true, keyword = false, abstract = false }
  Snacks.picker.pick({
    title = "ZK Search by Alias",
    items = make_items(notes_with_aliases, active_modes),
    format = function(item)
      return format_note_item(item, active_modes)
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd("cd " .. vim.fn.fnameescape(root))
        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
      end
    end,
  })
end

-- Search by keywords
function M.search_keyword()
  local all_notes = get_all_notes()
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

  local root = vim.fn.expand("~/wiki")
  local active_modes = { title = false, alias = false, keyword = true, abstract = false }
  Snacks.picker.pick({
    title = "ZK Search by Keyword",
    items = make_items(notes_with_keywords, active_modes),
    format = function(item)
      return format_note_item(item, active_modes)
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd("cd " .. vim.fn.fnameescape(root))
        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
      end
    end,
  })
end

-- Search by abstract
function M.search_abstract()
  local all_notes = get_all_notes()
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

  local root = vim.fn.expand("~/wiki")
  local active_modes = { title = false, alias = false, keyword = false, abstract = true }
  Snacks.picker.pick({
    title = "ZK Search by Abstract",
    items = make_items(notes_with_abstract, active_modes),
    format = function(item)
      return format_note_item(item, active_modes)
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd("cd " .. vim.fn.fnameescape(root))
        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
      end
    end,
  })
end

return M
