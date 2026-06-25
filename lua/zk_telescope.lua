local M = {}

local DEFAULT_METADATA_FIELDS = {
  { path = "schema-version", kind = "integer", source = "zk-lsp" },
  { path = "aliases", kind = "array-string", source = "zk-lsp" },
  { path = "abstract", kind = "string", source = "zk-lsp" },
  { path = "keywords", kind = "array-string", source = "zk-lsp" },
  { path = "generated", kind = "boolean", source = "zk-lsp" },
  { path = "checklist-status", kind = "string", source = "zk-lsp" },
  { path = "relation", kind = "string", source = "zk-lsp" },
  { path = "relation-target", kind = "array-string", source = "zk-lsp" },
}

local INACTIVE_RELATIONS = {
  archived = true,
  legacy = true,
}

local function wiki_root()
  return vim.fs.normalize((vim.uv.os_homedir() or vim.fn.expand("~")) .. "/wiki")
end

local function get_all_notes()
  return require("zk_cli").list_notes({ hydrate_metadata = true })
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

local function normalize_path(path)
  return type(path) == "string" and vim.trim(path) or ""
end

local function split_path(path)
  return vim.split(path, ".", { plain = true, trimempty = true })
end

local function get_path(tbl, path)
  local cur = tbl
  for _, part in ipairs(split_path(path)) do
    if type(cur) ~= "table" then
      return nil
    end
    cur = cur[part]
  end
  return cur
end

local function is_array(tbl)
  if type(tbl) ~= "table" then
    return false
  end
  local n = 0
  for key, _ in pairs(tbl) do
    if type(key) ~= "number" then
      return false
    end
    n = math.max(n, key)
  end
  return n == #tbl
end

local function value_to_parts(value, out)
  out = out or {}
  local t = type(value)
  if t == "string" then
    if value ~= "" then
      out[#out + 1] = value
    end
  elseif t == "number" or t == "boolean" then
    out[#out + 1] = tostring(value)
  elseif t == "table" then
    if is_array(value) then
      for _, item in ipairs(value) do
        value_to_parts(item, out)
      end
    else
      for _, item in pairs(value) do
        value_to_parts(item, out)
      end
    end
  end
  return out
end

local function value_to_text(value)
  return table.concat(value_to_parts(value), " ")
end

local function infer_kind(value)
  local t = type(value)
  if t == "boolean" then
    return "boolean"
  elseif t == "number" then
    return math.type and math.type(value) == "integer" and "integer" or "number"
  elseif t == "string" then
    return "string"
  elseif t == "table" and is_array(value) then
    local item_kind = "string"
    for _, item in ipairs(value) do
      item_kind = infer_kind(item)
      break
    end
    return "array-" .. item_kind
  elseif t == "table" then
    return "table"
  end
  return t
end

local function flatten_metadata(tbl, prefix, cb)
  if type(tbl) ~= "table" then
    return
  end
  for key, value in pairs(tbl) do
    if type(key) == "string" then
      local path = prefix and (prefix .. "." .. key) or key
      if type(value) == "table" and not is_array(value) then
        flatten_metadata(value, path, cb)
      else
        cb(path, value)
      end
    end
  end
end

local function parse_toml_value(raw)
  raw = vim.trim(raw or "")
  if raw == "true" then
    return true
  elseif raw == "false" then
    return false
  elseif raw == "[]" then
    return {}
  end
  local quoted = raw:match('^"(.*)"$')
  if quoted ~= nil then
    return quoted
  end
  return tonumber(raw) or raw
end

local function parse_metadata_schema(root)
  local path = root .. "/zk-lsp.toml"
  if vim.fn.filereadable(path) == 0 then
    return {}
  end

  local fields = {}
  local current
  for _, line in ipairs(vim.fn.readfile(path)) do
    line = line:gsub("#.*$", "")
    if line:match("^%s*%[%[metadata%.field%]%]%s*$") then
      if current and current.path then
        fields[#fields + 1] = current
      end
      current = { source = "zk-lsp.toml" }
    elseif current then
      local key, raw = line:match("^%s*([%w%-_]+)%s*=%s*(.-)%s*$")
      if key then
        current[key] = parse_toml_value(raw)
      elseif line:match("^%s*%[") then
        if current.path then
          fields[#fields + 1] = current
        end
        current = nil
      end
    end
  end
  if current and current.path then
    fields[#fields + 1] = current
  end
  return fields
end

local function metadata_registry(notes, root)
  local by_path = {}

  local function ensure(path, attrs)
    path = normalize_path(path)
    if path == "" then
      return nil
    end
    local item = by_path[path]
    if not item then
      item = {
        path = path,
        kind = attrs and attrs.kind or nil,
        source = attrs and attrs.source or nil,
        count = 0,
        sample = nil,
      }
      by_path[path] = item
    else
      item.kind = item.kind or (attrs and attrs.kind)
      item.source = item.source or (attrs and attrs.source)
    end
    if attrs and attrs.default ~= nil then
      item.default = attrs.default
    end
    return item
  end

  for _, field in ipairs(DEFAULT_METADATA_FIELDS) do
    ensure(field.path, field)
  end
  for _, field in ipairs(parse_metadata_schema(root)) do
    ensure(field.path, field)
  end

  for _, note in ipairs(notes) do
    flatten_metadata(note.metadata or {}, nil, function(path, value)
      local item = ensure(path, { kind = infer_kind(value), source = "note-info" })
      if item then
        local text = value_to_text(value)
        if text ~= "" then
          item.count = item.count + 1
          item.sample = item.sample or text:sub(1, 60)
        end
      end
    end)
  end

  local items = {}
  for _, item in pairs(by_path) do
    item.kind = item.kind or "string"
    item.source = item.source or "discovered"
    items[#items + 1] = item
  end
  table.sort(items, function(a, b)
    if a.count ~= b.count then
      return a.count > b.count
    end
    return a.path:lower() < b.path:lower()
  end)
  return items, by_path
end

local function index_key(index)
  if index.kind == "metadata" then
    return "metadata:" .. index.path
  end
  return index.kind
end

local function index_label(index)
  if index.kind == "metadata" then
    return index.path
  elseif index.kind == "metadata_all" then
    return "all metadata"
  end
  return index.kind
end

local function index_icon(index)
  if index.kind == "title" then
    return "󰗊"
  elseif index.kind == "tag" then
    return "󰓹"
  elseif index.kind == "metadata_all" then
    return "󰘦"
  end
  return "󰆼"
end

local function contains_index(indexes, target)
  local key = index_key(target)
  for _, index in ipairs(indexes) do
    if index_key(index) == key then
      return true
    end
  end
  return false
end

local function indexes_equal(indexes, target)
  return #indexes == 1 and contains_index(indexes, target)
end

local function indexes_for_mode(mode)
  mode = mode or "title"
  if mode == "all" then
    return { { kind = "metadata_all" } }
  elseif mode == "tag" then
    return { { kind = "tag" } }
  elseif mode == "alias" then
    return { { kind = "metadata", path = "aliases" } }
  elseif mode == "keyword" then
    return { { kind = "metadata", path = "keywords" } }
  elseif mode == "abstract" then
    return { { kind = "metadata", path = "abstract" } }
  elseif mode:match("^metadata:") then
    return { { kind = "metadata", path = mode:sub(10) } }
  end
  return { { kind = "title" } }
end

local function new_state(mode)
  return {
    indexes = indexes_for_mode(mode or "title"),
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

local function index_text(note, index)
  if index.kind == "title" then
    return note.title or ""
  elseif index.kind == "tag" then
    return join_values(note.tags)
  elseif index.kind == "metadata" then
    return value_to_text(get_path(note.metadata or {}, index.path))
  elseif index.kind == "metadata_all" then
    return value_to_text(note.metadata or {})
  end
  return ""
end

local function has_indexed_content(note, indexes)
  for _, index in ipairs(indexes) do
    if index_text(note, index) ~= "" then
      return true
    end
  end
  return #indexes == 0
end

local function keyword_filter_matches(note, wanted)
  wanted = wanted:lower()
  local keywords = note.keywords or get_path(note.metadata or {}, "keywords") or {}
  for _, keyword in ipairs(list_or_empty(keywords)) do
    if tostring(keyword):lower() == wanted then
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
    if has_indexed_content(note, state.indexes) then
      local ordinal_parts = {}
      for _, index in ipairs(state.indexes) do
        local text = index_text(note, index)
        if text ~= "" then
          ordinal_parts[#ordinal_parts + 1] = text:sub(1, index.kind == "metadata_all" and 500 or 200)
        end
      end

      if #ordinal_parts == 0 then
        ordinal_parts[#ordinal_parts + 1] = note.title or ""
      end

      local recency_bonus = n > 1 and (n - i) / (n - 1) * 20 or 20
      if is_inactive_note(note) then
        recency_bonus = recency_bonus - 8
      end

      local metadata = note.metadata or {}
      local aliases = metadata.aliases or note.aliases
      local keywords = metadata.keywords or note.keywords
      local abstract = metadata.abstract or note.abstract or ""

      items[#items + 1] = {
        text = table.concat(ordinal_parts, " "),
        title = note.title,
        alias = has_values(aliases) and join_values(aliases) or nil,
        keyword = has_values(keywords) and join_values(keywords) or nil,
        tag = has_values(note.tags) and join_values(note.tags) or nil,
        abstract = abstract ~= "" and abstract or nil,
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

local function should_show_index(state, index)
  return contains_index(state.indexes, index) or contains_index(state.indexes, { kind = "metadata_all" })
end

local function format_note_item(item, state)
  local note = item._note
  local metadata = note.metadata or {}
  local aliases = metadata.aliases or note.aliases
  local keywords = metadata.keywords or note.keywords
  local abstract = metadata.abstract or note.abstract or ""
  local ret = {}

  ret[#ret + 1] = { "󰈙 ", "SnacksPickerIcon", virtual = true }
  ret[#ret + 1] = { note.title, "SnacksPickerFile" }

  if INACTIVE_RELATIONS[item.relation] then
    add_virtual(ret, "  ")
    local icon = item.relation == "legacy" and "󰦪" or "󰉉"
    ret[#ret + 1] = format_badge(icon .. " " .. item.relation, "SnacksPickerDimmed")
  end

  if should_show_index(state, { kind = "metadata", path = "aliases" }) and has_values(aliases) then
    add_virtual(ret, "  ")
    ret[#ret + 1] = { table.concat(aliases, ", "), "SnacksPickerDimmed" }
  end

  if should_show_index(state, { kind = "metadata", path = "abstract" }) and abstract ~= "" then
    add_virtual(ret, "  ")
    local shown = abstract:sub(1, 60) .. (abstract:len() > 60 and "…" or "")
    ret[#ret + 1] = { shown, "SnacksPickerComment" }
  end

  if
    (should_show_index(state, { kind = "metadata", path = "keywords" }) or #state.keyword_filters > 0)
    and has_values(keywords)
  then
    add_virtual(ret, "  ")
    for i, keyword in ipairs(keywords) do
      if i > 1 then
        add_virtual(ret, " ")
      end
      ret[#ret + 1] = { "[" .. keyword .. "]", "SnacksPickerSpecial" }
    end
  end

  if (should_show_index(state, { kind = "tag" }) or state.tag_filter) and has_values(note.tags) then
    add_virtual(ret, "  ")
    for i, tag in ipairs(note.tags) do
      if i > 1 then
        add_virtual(ret, " ")
      end
      ret[#ret + 1] = { "#" .. tag, "SnacksPickerSpecial" }
    end
  end

  for _, index in ipairs(state.indexes) do
    if index.kind == "metadata" and not ({ aliases = true, abstract = true, keywords = true })[index.path] then
      local text = index_text(note, index)
      if text ~= "" then
        add_virtual(ret, "  ")
        local shown = text:sub(1, 50) .. (text:len() > 50 and "…" or "")
        ret[#ret + 1] = { index.path .. "=" .. shown, "SnacksPickerDimmed" }
      end
    end
  end

  return ret
end

local function mode_label(state)
  if #state.indexes == 0 then
    return "none"
  end
  local names = {}
  for _, index in ipairs(state.indexes) do
    names[#names + 1] = index_label(index)
  end
  return table.concat(names, "+")
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
    local values = note.keywords or get_path(note.metadata or {}, "keywords") or {}
    for _, keyword in ipairs(list_or_empty(values)) do
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

local function open_note(root, item)
  if not item then
    return
  end
  vim.cmd("cd " .. vim.fn.fnameescape(root))
  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
end

function M.search_with_filters(opts)
  opts = type(opts) == "table" and opts or {}
  local root = wiki_root()
  local all_notes = get_all_notes()

  if #all_notes == 0 then
    vim.notify("No notes found", vim.log.levels.INFO)
    return
  end

  local registry = metadata_registry(all_notes, root)
  local state = new_state(opts.mode or "title")

  local open_picker
  local open_mode_menu
  local open_filter_menu
  local open_tag_menu
  local open_keyword_menu

  local function scoped_notes()
    return apply_filters(all_notes, {
      indexes = state.indexes,
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

  local function toggle_index(index)
    if contains_index(state.indexes, index) then
      local next_indexes = {}
      local key = index_key(index)
      for _, existing in ipairs(state.indexes) do
        if index_key(existing) ~= key then
          next_indexes[#next_indexes + 1] = existing
        end
      end
      state.indexes = #next_indexes > 0 and next_indexes or { { kind = "title" } }
    else
      local next_indexes = {}
      for _, existing in ipairs(state.indexes) do
        if existing.kind ~= "metadata_all" then
          next_indexes[#next_indexes + 1] = existing
        end
      end
      next_indexes[#next_indexes + 1] = index
      state.indexes = next_indexes
    end
  end

  open_mode_menu = function()
    local mode_items = {
      { text = "title", index = { kind = "title" }, label = "Title", icon = "󰗊", desc = "note titles" },
      { text = "tag", index = { kind = "tag" }, label = "Tag", icon = "󰓹", desc = "inline tags" },
      {
        text = "all metadata",
        index = { kind = "metadata_all" },
        label = "All metadata",
        icon = "󰘦",
        desc = "all metadata leaf fields",
      },
    }
    for _, field in ipairs(registry) do
      mode_items[#mode_items + 1] = {
        text = field.path,
        index = { kind = "metadata", path = field.path },
        label = field.path,
        icon = "󰆼",
        desc = (field.kind or "")
          .. " · "
          .. tostring(field.count or 0)
          .. " notes"
          .. (field.sample and (" · " .. field.sample) or ""),
      }
    end

    local confirmed = false
    Snacks.picker.pick({
      title = "󰠮 ZK index field (CR=single, Space=toggle multi)",
      layout = "select",
      win = {
        input = {
          keys = { ["<Space>"] = { "toggle_index", mode = { "i", "n" }, desc = "toggle multi-index" }, ["?"] = false },
        },
        list = { keys = { ["<Space>"] = { "toggle_index", desc = "toggle multi-index" }, ["?"] = false } },
      },
      items = mode_items,
      format = function(item)
        local active = contains_index(state.indexes, item.index)
        return {
          { active and "● " or "○ ", active and "SnacksPickerSpecial" or "SnacksPickerDimmed" },
          { item.icon .. " " .. item.label, active and "SnacksPickerFile" or "SnacksPickerDimmed" },
          { "  " .. item.desc, "SnacksPickerDimmed" },
        }
      end,
      confirm = function(sub_picker, item)
        confirmed = true
        if item then
          state.indexes = { item.index }
        end
        sub_picker:close()
        reopen()
      end,
      actions = {
        toggle_index = {
          desc = "toggle multi-index",
          action = function(sub_picker, item)
            confirmed = true
            if item then
              toggle_index(item.index)
            end
            sub_picker:close()
            reopen()
          end,
        },
      },
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
          return { { "󰅖 ", "SnacksPickerSpecial" }, { item.label, "SnacksPickerFile" } }
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
          return { { "󰅖 ", "SnacksPickerSpecial" }, { item.label, "SnacksPickerFile" } }
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
        reset_state = {
          desc = "reset ZK search state",
          action = function(picker)
            capture_query(picker)
            state.indexes = indexes_for_mode("title")
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
