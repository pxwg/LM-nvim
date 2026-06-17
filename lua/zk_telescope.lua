local M = {}

local FIELD_DEFS = {
  { name = "title", label = "Title", icon = "󰗊", desc = "note titles" },
  { name = "alias", label = "Alias", icon = "󰌹", desc = "aliases / alternate names" },
  { name = "abstract", label = "Abstract", icon = "󰦨", desc = "abstract summaries" },
  { name = "keyword", label = "Keyword", icon = "󰌋", desc = "metadata keywords" },
  { name = "tag", label = "Tag", icon = "󰓹", desc = "inline #tag metadata" },
}

local FIELD_ORDER = vim.tbl_map(function(field)
  return field.name
end, FIELD_DEFS)

local INACTIVE_RELATIONS = {
  archived = true,
  legacy = true,
}

local function get_all_notes()
  return require("zk_cli").list_notes()
end

local function list_or_empty(value)
  return type(value) == "table" and value or {}
end

local function join_values(values)
  return table.concat(list_or_empty(values), " ")
end

local function has_values(values)
  return #list_or_empty(values) > 0
end

local function mode_count(modes)
  local count = 0
  for _, name in ipairs(FIELD_ORDER) do
    if modes[name] then
      count = count + 1
    end
  end
  return count
end

local function all_modes_enabled(modes)
  return mode_count(modes) == #FIELD_ORDER
end

local function modes_for(mode)
  mode = mode or "title"
  local modes = {}
  for _, name in ipairs(FIELD_ORDER) do
    modes[name] = mode == "all"
  end
  if mode ~= "all" and modes[mode] ~= nil then
    modes[mode] = true
  elseif mode ~= "all" then
    modes.title = true
  end
  return modes
end

local function new_state(mode)
  return {
    modes = modes_for(mode or "title"),
    tag_filter = nil,
    keyword_filters = {},
    include_inactive = false,
    query = "",
  }
end

local function get_relation(note)
  local metadata = note.metadata or {}
  local relation = metadata.relation or note.relation or ""
  if type(relation) ~= "string" then
    return ""
  end
  return vim.trim(relation):lower()
end

local function is_inactive_note(note)
  return INACTIVE_RELATIONS[get_relation(note)] == true
end

local function field_text(note, field)
  if field == "title" then
    return note.title or ""
  elseif field == "alias" then
    return join_values(note.aliases)
  elseif field == "abstract" then
    return note.abstract or ""
  elseif field == "keyword" then
    return join_values(note.keywords)
  elseif field == "tag" then
    return join_values(note.tags)
  end
  return ""
end

local function has_indexed_content(note, modes)
  local has_active_mode = false
  for _, field in ipairs(FIELD_ORDER) do
    if modes[field] then
      has_active_mode = true
      if field_text(note, field) ~= "" then
        return true
      end
    end
  end
  return not has_active_mode
end

local function keyword_filter_matches(note, wanted)
  wanted = wanted:lower()
  for _, keyword in ipairs(list_or_empty(note.keywords)) do
    if keyword:lower() == wanted then
      return true
    end
  end
  return false
end

local function apply_filters(notes, state)
  local filtered = {}

  for _, note in ipairs(notes) do
    if state.include_inactive or not is_inactive_note(note) then
      filtered[#filtered + 1] = note
    end
  end

  if state.tag_filter then
    local tag_filtered = {}
    for _, note in ipairs(filtered) do
      for _, tag in ipairs(list_or_empty(note.tags)) do
        if tag == state.tag_filter then
          tag_filtered[#tag_filtered + 1] = note
          break
        end
      end
    end
    filtered = tag_filtered
  end

  if #state.keyword_filters > 0 then
    local keyword_filtered = {}
    for _, note in ipairs(filtered) do
      local matches = true
      for _, keyword in ipairs(state.keyword_filters) do
        if not keyword_filter_matches(note, keyword) then
          matches = false
          break
        end
      end
      if matches then
        keyword_filtered[#keyword_filtered + 1] = note
      end
    end
    filtered = keyword_filtered
  end

  return filtered
end

local function make_items(notes, state)
  local n = #notes
  local items = {}

  for i, note in ipairs(notes) do
    if has_indexed_content(note, state.modes) then
      local ordinal_parts = {}
      for _, field in ipairs(FIELD_ORDER) do
        if state.modes[field] then
          local text = field_text(note, field)
          if text ~= "" then
            if field == "abstract" then
              text = text:sub(1, 200)
            end
            ordinal_parts[#ordinal_parts + 1] = text
          end
        end
      end

      if #ordinal_parts == 0 then
        ordinal_parts[#ordinal_parts + 1] = note.title or ""
      end

      -- Recency bonus: newer notes (earlier in desc-sorted list) get a higher score_add.
      -- Range 0–20, small enough not to dominate fuzzy score but meaningful as a tiebreaker.
      local recency_bonus = n > 1 and (n - i) / (n - 1) * 20 or 20
      if is_inactive_note(note) then
        recency_bonus = recency_bonus - 8
      end

      items[#items + 1] = {
        text = table.concat(ordinal_parts, " "),
        title = note.title,
        alias = has_values(note.aliases) and join_values(note.aliases) or nil,
        keyword = has_values(note.keywords) and join_values(note.keywords) or nil,
        tag = has_values(note.tags) and join_values(note.tags) or nil,
        abstract = note.abstract ~= "" and note.abstract or nil,
        relation = get_relation(note),
        file = note.path,
        pos = { note.title_line, 0 },
        _note = note,
        score_add = recency_bonus,
      }
    end
  end

  return items
end

local function add_virtual(ret, text)
  ret[#ret + 1] = { text, virtual = true }
end

local function format_badge(text, hl)
  return { " " .. text .. " ", hl or "SnacksPickerDimmed" }
end

local function format_note_item(item, state)
  local note = item._note
  local ret = {}
  local show_all = all_modes_enabled(state.modes)

  ret[#ret + 1] = { "󰈙 ", "SnacksPickerIcon", virtual = true }
  ret[#ret + 1] = { note.title, "SnacksPickerFile" }

  if INACTIVE_RELATIONS[item.relation] then
    add_virtual(ret, "  ")
    local icon = item.relation == "legacy" and "󰦪" or "󰉉"
    ret[#ret + 1] = format_badge(icon .. " " .. item.relation, "SnacksPickerDimmed")
  end

  if (state.modes.alias or show_all) and has_values(note.aliases) then
    add_virtual(ret, "  ")
    ret[#ret + 1] = { table.concat(note.aliases, ", "), "SnacksPickerDimmed" }
  end

  if (state.modes.abstract or show_all) and note.abstract ~= "" then
    add_virtual(ret, "  ")
    local abstract = note.abstract:sub(1, 60) .. (note.abstract:len() > 60 and "…" or "")
    ret[#ret + 1] = { abstract, "SnacksPickerComment" }
  end

  if (state.modes.keyword or show_all or #state.keyword_filters > 0) and has_values(note.keywords) then
    add_virtual(ret, "  ")
    for i, keyword in ipairs(note.keywords) do
      if i > 1 then
        add_virtual(ret, " ")
      end
      ret[#ret + 1] = { "[" .. keyword .. "]", "SnacksPickerSpecial" }
    end
  end

  if (state.modes.tag or show_all or state.tag_filter) and has_values(note.tags) then
    add_virtual(ret, "  ")
    for i, tag in ipairs(note.tags) do
      if i > 1 then
        add_virtual(ret, " ")
      end
      ret[#ret + 1] = { "#" .. tag, "SnacksPickerSpecial" }
    end
  end

  return ret
end

local function mode_label(state)
  if all_modes_enabled(state.modes) then
    return "all"
  end

  local names = {}
  for _, field in ipairs(FIELD_DEFS) do
    if state.modes[field.name] then
      names[#names + 1] = field.name
    end
  end
  return #names > 0 and table.concat(names, "+") or "none"
end

local function filter_label(state)
  local filters = {}
  if state.tag_filter then
    filters[#filters + 1] = "#" .. state.tag_filter
  end
  for _, keyword in ipairs(state.keyword_filters) do
    filters[#filters + 1] = "[" .. keyword .. "]"
  end
  return #filters > 0 and table.concat(filters, " ") or "∅"
end

local function picker_title(state)
  local scope = state.include_inactive and "all" or "active"
  return ("󰠮 ZK · %s · %s · %s · m:idx f:filter R:reset"):format(mode_label(state), scope, filter_label(state))
end

local function no_help_win()
  return {
    input = { keys = { ["?"] = false } },
    list = { keys = { ["?"] = false } },
  }
end

local function sorted_keys(set)
  local keys = {}
  for key, _ in pairs(set) do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(a, b)
    return a:lower() < b:lower()
  end)
  return keys
end

local function collect_tags(notes)
  local tags = {}
  for _, note in ipairs(notes) do
    for _, tag in ipairs(list_or_empty(note.tags)) do
      tags[tag] = true
    end
  end
  return sorted_keys(tags)
end

local function collect_keywords(notes)
  local keywords = {}
  for _, note in ipairs(notes) do
    for _, keyword in ipairs(list_or_empty(note.keywords)) do
      keywords[keyword] = true
    end
  end
  return sorted_keys(keywords)
end

local function keyword_filter_set(state)
  local set = {}
  for _, keyword in ipairs(state.keyword_filters) do
    set[keyword] = true
  end
  return set
end

local function toggle_keyword_filter(state, keyword)
  local next_filters = {}
  local removed = false
  for _, existing in ipairs(state.keyword_filters) do
    if existing == keyword then
      removed = true
    else
      next_filters[#next_filters + 1] = existing
    end
  end
  if not removed then
    next_filters[#next_filters + 1] = keyword
  end
  state.keyword_filters = next_filters
end

local function is_menu_mode_active(state, mode)
  if mode == "all" then
    return all_modes_enabled(state.modes)
  end
  return state.modes[mode] and mode_count(state.modes) == 1
end

local function open_note(root, item)
  if not item then
    return
  end
  vim.cmd("cd " .. vim.fn.fnameescape(root))
  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
end

function M.search_with_filters(opts)
  opts = type(opts) == "table" and opts or {}
  local all_notes = get_all_notes()

  if #all_notes == 0 then
    vim.notify("No notes found", vim.log.levels.INFO)
    return
  end

  local state = new_state(opts.mode or "title")
  local root = vim.fn.expand("~/wiki")

  local open_picker
  local open_mode_menu
  local open_filter_menu
  local open_tag_menu
  local open_keyword_menu

  local function scoped_notes()
    return apply_filters(all_notes, {
      modes = state.modes,
      tag_filter = nil,
      keyword_filters = {},
      include_inactive = state.include_inactive,
      query = state.query,
    })
  end

  local function reopen()
    vim.schedule(function()
      open_picker()
    end)
  end

  local function capture_query(picker)
    if picker and picker.input then
      state.query = picker.input:get()
    end
  end

  local function close_then(picker, callback)
    capture_query(picker)
    picker:close()
    vim.schedule(callback)
  end

  local function normal_mode()
    if vim.fn.mode():find("^i") then
      vim.cmd.stopinsert()
    end
  end

  open_mode_menu = function()
    local mode_items = {
      { text = "title", mode = "title", icon = "󰗊", label = "Title", desc = "search by note title" },
      { text = "alias", mode = "alias", icon = "󰌹", label = "Alias", desc = "search by aliases" },
      { text = "abstract", mode = "abstract", icon = "󰦨", label = "Abstract", desc = "search inside abstracts" },
      { text = "keyword", mode = "keyword", icon = "󰌋", label = "Keyword", desc = "search metadata keywords" },
      { text = "tag", mode = "tag", icon = "󰓹", label = "Tag", desc = "search inline tags" },
      {
        text = "all",
        mode = "all",
        icon = "󰘦",
        label = "All metadata",
        desc = "title + alias + abstract + keyword + tag",
      },
    }
    local confirmed = false

    Snacks.picker.pick({
      title = "󰠮 ZK index mode",
      layout = "select",
      win = no_help_win(),
      items = mode_items,
      format = function(item)
        local active = is_menu_mode_active(state, item.mode)
        return {
          { active and "● " or "○ ", active and "SnacksPickerSpecial" or "SnacksPickerDimmed" },
          { item.icon .. " " .. item.label, active and "SnacksPickerFile" or "SnacksPickerDimmed" },
          { "  " .. item.desc, "SnacksPickerDimmed" },
        }
      end,
      confirm = function(sub_picker, item)
        confirmed = true
        if item then
          state.modes = modes_for(item.mode)
        end
        sub_picker:close()
        reopen()
      end,
      on_close = function()
        if not confirmed then
          reopen()
        end
      end,
    })
  end

  open_tag_menu = function()
    local tags = collect_tags(scoped_notes())
    if #tags == 0 and not state.tag_filter then
      vim.notify("No tags available", vim.log.levels.INFO)
      reopen()
      return
    end

    local items = {}
    if state.tag_filter then
      items[#items + 1] = { text = "clear tag filter", clear = true, label = "Clear tag filter" }
    end
    for _, tag in ipairs(tags) do
      items[#items + 1] = { text = tag, tag = tag, label = "#" .. tag }
    end

    local confirmed = false
    Snacks.picker.pick({
      title = "󰓹 ZK tag filter",
      layout = "select",
      win = no_help_win(),
      items = items,
      format = function(item)
        if item.clear then
          return {
            { "󰅖 ", "SnacksPickerSpecial" },
            { item.label, "SnacksPickerFile" },
          }
        end
        local active = state.tag_filter == item.tag
        return {
          { active and "● " or "○ ", active and "SnacksPickerSpecial" or "SnacksPickerDimmed" },
          { item.label, active and "SnacksPickerFile" or "SnacksPickerSpecial" },
        }
      end,
      confirm = function(sub_picker, item)
        confirmed = true
        if item then
          state.tag_filter = item.clear and nil or item.tag
        end
        sub_picker:close()
        reopen()
      end,
      on_close = function()
        if not confirmed then
          reopen()
        end
      end,
    })
  end

  open_keyword_menu = function()
    local keywords = collect_keywords(scoped_notes())
    if #keywords == 0 and #state.keyword_filters == 0 then
      vim.notify("No keywords available", vim.log.levels.INFO)
      reopen()
      return
    end

    local selected = keyword_filter_set(state)
    local items = {}
    if #state.keyword_filters > 0 then
      items[#items + 1] = { text = "clear keyword filters", clear = true, label = "Clear keyword filters" }
    end
    for _, keyword in ipairs(keywords) do
      items[#items + 1] = { text = keyword, keyword = keyword, label = "[" .. keyword .. "]" }
    end

    local confirmed = false
    Snacks.picker.pick({
      title = "󰌋 ZK keyword filter",
      layout = "select",
      win = no_help_win(),
      items = items,
      format = function(item)
        if item.clear then
          return {
            { "󰅖 ", "SnacksPickerSpecial" },
            { item.label, "SnacksPickerFile" },
          }
        end
        local active = selected[item.keyword]
        return {
          { active and "● " or "○ ", active and "SnacksPickerSpecial" or "SnacksPickerDimmed" },
          { item.label, active and "SnacksPickerFile" or "SnacksPickerSpecial" },
        }
      end,
      confirm = function(sub_picker, item)
        confirmed = true
        if item then
          if item.clear then
            state.keyword_filters = {}
          else
            toggle_keyword_filter(state, item.keyword)
          end
        end
        sub_picker:close()
        reopen()
      end,
      on_close = function()
        if not confirmed then
          reopen()
        end
      end,
    })
  end

  open_filter_menu = function()
    local filter_items = {
      {
        text = "tag",
        action = "tag",
        icon = "󰓹",
        label = "Tag filter",
        desc = state.tag_filter and ("current: #" .. state.tag_filter) or "choose a tag",
      },
      {
        text = "keyword",
        action = "keyword",
        icon = "󰌋",
        label = "Keyword filter",
        desc = #state.keyword_filters > 0 and table.concat(state.keyword_filters, ", ") or "toggle keywords",
      },
      {
        text = "archive",
        action = "archive",
        icon = "󰉉",
        label = "Archived / legacy",
        desc = state.include_inactive and "shown in results" or "hidden by default",
      },
      {
        text = "clear",
        action = "clear",
        icon = "󰅖",
        label = "Clear filters",
        desc = "remove tag and keyword filters",
      },
    }
    local confirmed = false

    Snacks.picker.pick({
      title = "󰈲 ZK filters",
      layout = "select",
      win = no_help_win(),
      items = filter_items,
      format = function(item)
        local active = (item.action == "tag" and state.tag_filter ~= nil)
          or (item.action == "keyword" and #state.keyword_filters > 0)
          or (item.action == "archive" and state.include_inactive)
        return {
          { active and "● " or "○ ", active and "SnacksPickerSpecial" or "SnacksPickerDimmed" },
          { item.icon .. " " .. item.label, active and "SnacksPickerFile" or "SnacksPickerDimmed" },
          { "  " .. item.desc, "SnacksPickerDimmed" },
        }
      end,
      confirm = function(sub_picker, item)
        confirmed = true
        if not item then
          sub_picker:close()
          reopen()
          return
        end

        if item.action == "tag" then
          sub_picker:close()
          vim.schedule(open_tag_menu)
        elseif item.action == "keyword" then
          sub_picker:close()
          vim.schedule(open_keyword_menu)
        elseif item.action == "archive" then
          state.include_inactive = not state.include_inactive
          sub_picker:close()
          reopen()
        elseif item.action == "clear" then
          state.tag_filter = nil
          state.keyword_filters = {}
          sub_picker:close()
          reopen()
        end
      end,
      on_close = function()
        if not confirmed then
          reopen()
        end
      end,
    })
  end

  open_picker = function()
    local notes = apply_filters(all_notes, state)

    Snacks.picker.pick({
      title = picker_title(state),
      pattern = state.query,
      show_empty = true,
      items = make_items(notes, state),
      format = function(item)
        return format_note_item(item, state)
      end,
      confirm = function(picker, item)
        picker:close()
        open_note(root, item)
      end,
      win = {
        input = {
          keys = {
            ["<Esc>"] = { "smart_escape", mode = { "i", "n" }, desc = "normal mode / close" },
            ["m"] = { "select_mode", mode = "n", desc = "choose index mode" },
            ["f"] = { "select_filter", mode = "n", desc = "choose filters" },
            ["R"] = { "reset_state", mode = "n", desc = "reset ZK search state" },
            ["?"] = false,
          },
        },
        list = {
          keys = {
            ["m"] = { "select_mode", desc = "choose index mode" },
            ["f"] = { "select_filter", desc = "choose filters" },
            ["R"] = { "reset_state", desc = "reset ZK search state" },
            ["?"] = false,
          },
        },
      },
      actions = {
        smart_escape = {
          desc = "normal mode / close",
          action = function(picker)
            if vim.fn.mode():find("^i") then
              normal_mode()
            else
              picker:close()
            end
          end,
        },
        select_mode = {
          desc = "choose index mode",
          action = function(picker)
            close_then(picker, open_mode_menu)
          end,
        },
        select_filter = {
          desc = "choose filters",
          action = function(picker)
            close_then(picker, open_filter_menu)
          end,
        },
        toggle_inactive = {
          desc = "toggle archived/legacy notes",
          action = function(picker)
            capture_query(picker)
            state.include_inactive = not state.include_inactive
            picker:close()
            reopen()
          end,
        },
        reset_state = {
          desc = "reset ZK search state",
          action = function(picker)
            capture_query(picker)
            state.modes = modes_for("title")
            state.tag_filter = nil
            state.keyword_filters = {}
            state.include_inactive = false
            picker:close()
            reopen()
          end,
        },
      },
    })
  end

  open_picker()
end

function M.search_title()
  M.search_with_filters({ mode = "title" })
end

function M.search_alias()
  M.search_with_filters({ mode = "alias" })
end

function M.search_keyword()
  M.search_with_filters({ mode = "keyword" })
end

function M.search_abstract()
  M.search_with_filters({ mode = "abstract" })
end

function M.search_tag()
  M.search_with_filters({ mode = "tag" })
end

return M
