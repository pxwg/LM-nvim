local M = {}

local function trim(value)
  if type(value) ~= "string" then
    return ""
  end
  local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
  return trimmed
end

local function collapse_ws(value)
  return trim((value or ""):gsub("%s+", " "))
end

local function join_paths(...)
  local path = table.concat({ ... }, "/"):gsub("//+", "/")
  return path
end

local function split_lines(text)
  local lines = {}
  for line in ((text or "") .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

local function read_file_text(path)
  if vim.fn.filereadable(path) == 0 then
    return ""
  end
  return table.concat(vim.fn.readfile(path), "\n")
end

local function line_for_offset(text, offset)
  local _, count = text:sub(1, math.max(offset - 1, 0)):gsub("\n", "")
  return count + 1
end

local function strip_wrapping_braces(value)
  value = trim(value)
  while value:match("^{.*}$") do
    local depth = 0
    local balanced = true
    for i = 1, #value do
      local ch = value:sub(i, i)
      if ch == "{" then
        depth = depth + 1
      elseif ch == "}" then
        depth = depth - 1
        if depth == 0 and i < #value then
          balanced = false
          break
        end
      end
      if depth < 0 then
        balanced = false
        break
      end
    end
    if not balanced or depth ~= 0 then
      break
    end
    value = trim(value:sub(2, -2))
  end
  return value
end

local function normalize_field_value(value)
  value = strip_wrapping_braces(value or "")
  value = value:gsub("\\\n%s*", " ")
  return collapse_ws(value)
end

local function read_braced_value(text, pos)
  local depth = 1
  local i = pos + 1
  while i <= #text do
    local ch = text:sub(i, i)
    if ch == "{" then
      depth = depth + 1
    elseif ch == "}" then
      depth = depth - 1
      if depth == 0 then
        return text:sub(pos + 1, i - 1), i + 1
      end
    end
    i = i + 1
  end
  return text:sub(pos + 1), #text + 1
end

local function read_quoted_value(text, pos)
  local i = pos + 1
  while i <= #text do
    local ch = text:sub(i, i)
    local prev = i > 1 and text:sub(i - 1, i - 1) or ""
    if ch == '"' and prev ~= "\\" then
      return text:sub(pos + 1, i - 1), i + 1
    end
    i = i + 1
  end
  return text:sub(pos + 1), #text + 1
end

local function read_bare_value(text, pos)
  local i = pos
  while i <= #text do
    local ch = text:sub(i, i)
    if ch == "," or ch == "\n" or ch == "}" or ch == ")" then
      break
    end
    i = i + 1
  end
  return text:sub(pos, i - 1), i
end

local function parse_fields(body)
  local fields = {}
  local pos = 1

  while pos <= #body do
    local start_idx, eq_idx, name = body:find("([%a][%w_%-%:]*)%s*=", pos)
    if not start_idx then
      break
    end

    pos = eq_idx + 1
    while pos <= #body and body:sub(pos, pos):match("%s") do
      pos = pos + 1
    end

    local ch = body:sub(pos, pos)
    local value
    if ch == "{" then
      value, pos = read_braced_value(body, pos)
    elseif ch == '"' then
      value, pos = read_quoted_value(body, pos)
    else
      value, pos = read_bare_value(body, pos)
    end

    fields[name:lower()] = normalize_field_value(value)
  end

  return fields
end

local function parse_entries_from_text(text)
  local entries = {}
  local pos = 1

  while true do
    local entry_start, type_end, entry_type, open_char = text:find("@([%a][%w%-]*)%s*([%{%(%[])", pos)
    if not entry_start then
      break
    end

    local close_char = open_char == "{" and "}" or (open_char == "(" and ")" or "]")
    local depth = 1
    local i = type_end + 1
    local in_quote = false
    local entry_end

    while i <= #text do
      local ch = text:sub(i, i)
      local prev = i > 1 and text:sub(i - 1, i - 1) or ""
      if ch == '"' and prev ~= "\\" then
        in_quote = not in_quote
      end
      if not in_quote then
        if open_char == "{" then
          if ch == "{" then
            depth = depth + 1
          elseif ch == "}" then
            depth = depth - 1
          end
        else
          if ch == open_char then
            depth = depth + 1
          elseif ch == close_char then
            depth = depth - 1
          end
        end
        if depth == 0 then
          entry_end = i
          break
        end
      end
      i = i + 1
    end

    if not entry_end then
      break
    end

    local entry_text = text:sub(entry_start, entry_end)
    local first_comma = entry_text:find(",", 1, true)
    local raw_key = first_comma and trim(entry_text:sub(entry_text:find(open_char, 1, true) + 1, first_comma - 1)) or ""
    local key = raw_key
    if key:match("[%s=]") then
      key = ""
    end

    local body = first_comma and entry_text:sub(first_comma + 1, -2) or ""
    entries[#entries + 1] = {
      type = entry_type:lower(),
      key = key,
      raw_key = raw_key,
      text = entry_text,
      fields = parse_fields(body),
      start_line = line_for_offset(text, entry_start),
      end_line = line_for_offset(text, entry_end),
      start_offset = entry_start,
      end_offset = entry_end,
    }

    pos = entry_end + 1
  end

  return entries
end

local function normalize_doi(value)
  value = trim(value or "")
  value = value:gsub("^https?://dx%.doi%.org/", "")
  value = value:gsub("^https?://doi%.org/", "")
  return value:lower()
end

local function normalize_url(value)
  value = trim(value or "")
  value = value:gsub("%s+", "")
  value = value:gsub("#.*$", "")
  value = value:gsub("%?$", "")
  value = value:gsub("/$", "")
  return value
end

local function normalize_file_path(value)
  value = trim(value or "")
  if value:sub(1, 1) == "~" then
    value = vim.fn.expand(value)
  end
  return value:gsub("/+$", "")
end

local function normalize_arxiv_id(value)
  value = trim(value or "")
  if value == "" then
    return ""
  end
  value = value:gsub("^arXiv:", "")
  value = value:gsub("^https?://arxiv%.org/abs/", "")
  value = value:gsub("^https?://arxiv%.org/pdf/", "")
  value = value:gsub("%.pdf$", "")
  value = value:gsub("^https?://doi%.org/10%.48550/arXiv%.", "")
  value = value:gsub("^10%.48550/arXiv%.", "")
  value = value:gsub("v%d+$", "")
  return value:lower()
end

local function parse_file_field_items(file_field)
  local items = {}
  for item in (file_field or ""):gmatch("([^;]+)") do
    item = trim(item)
    if item ~= "" then
      items[#items + 1] = item
    end
  end
  return items
end

local function zotero_file_candidate(item)
  local before_mime = item:gsub(":application/[%w%+%-%.]+$", "")
  if before_mime ~= item and not before_mime:match("^%a[%w+.-]*://") then
    local dropped = before_mime:match("^[^:]+:(.+)$")
    if dropped and dropped ~= "" then
      return dropped
    end
  end
  return item
end

local function candidate_has_ext(candidate, exts)
  local lower = candidate:lower()
  for _, ext in ipairs(exts) do
    if lower:match("%." .. ext .. "$") then
      return true
    end
  end
  return false
end

local function extract_file_by_ext(file_field, exts)
  for _, item in ipairs(parse_file_field_items(file_field)) do
    local candidate = zotero_file_candidate(item)
    if candidate_has_ext(candidate, exts) then
      return candidate
    end
  end
  return nil
end

local function bib_escape(value)
  value = collapse_ws(value or "")
  return value:gsub("[{}]", "")
end

function M.wiki_root(root)
  return vim.fn.expand(root or "~/wiki")
end

function M.bib_path(root)
  return join_paths(M.wiki_root(root), "ref.bib")
end

function M.parse_text(text)
  return parse_entries_from_text(text or "")
end

function M.parse_file(path)
  return parse_entries_from_text(read_file_text(path or M.bib_path()))
end

function M.parse_entry(text)
  return parse_entries_from_text(text or "")[1]
end

function M.field(entry, name)
  if not entry or type(entry.fields) ~= "table" then
    return ""
  end
  return entry.fields[(name or ""):lower()] or ""
end

function M.find_entry_by_key(key, opts)
  key = trim((key or ""):gsub("^@", ""))
  if key == "" then
    return nil
  end
  local path = (opts and opts.bib_path) or M.bib_path(opts and opts.wiki_root)
  for _, entry in ipairs(M.parse_file(path)) do
    if entry.key == key then
      entry.bib_path = path
      return entry
    end
  end
  return nil
end

function M.extract_arxiv_id(value)
  value = trim(value or "")
  return value:match("arxiv%.org/abs/([^?#/]+)")
    or value:match("arxiv%.org/pdf/([^?#/]+)%.pdf")
    or value:match("^arXiv:(.+)$")
    or value:match("^arxiv:(.+)$")
    or value:match("10%.48550/arXiv%.([^%s}]+)")
end

function M.find_duplicate(query, opts)
  query = query or {}
  local path = (opts and opts.bib_path) or M.bib_path(opts and opts.wiki_root)
  local parsed = query.entry or (query.bibtex and M.parse_entry(query.bibtex)) or nil
  local fields = vim.deepcopy((parsed and parsed.fields) or {})
  for key, value in pairs(query.fields or {}) do
    fields[key:lower()] = value
  end

  local key = trim(query.key or (parsed and parsed.key) or "")
  local doi = normalize_doi(query.doi or fields.doi or "")
  local url = normalize_url(query.url or fields.url or fields.howpublished or "")
  local file_value = trim(query.file or fields.file or "")
  local eprint = normalize_arxiv_id(query.eprint or fields.eprint or M.extract_arxiv_id(url) or "")

  for _, entry in ipairs(M.parse_file(path)) do
    entry.bib_path = path
    if key ~= "" and entry.key == key then
      return entry, "key"
    end

    local entry_doi = normalize_doi(M.field(entry, "doi"))
    if doi ~= "" and entry_doi ~= "" and doi == entry_doi then
      return entry, "doi"
    end

    local entry_url =
      normalize_url(M.field(entry, "url") ~= "" and M.field(entry, "url") or M.field(entry, "howpublished"))
    local entry_eprint = normalize_arxiv_id(
      M.field(entry, "eprint") ~= "" and M.field(entry, "eprint") or M.extract_arxiv_id(entry_url) or ""
    )
    if eprint ~= "" and entry_eprint ~= "" and eprint == entry_eprint then
      return entry, "eprint"
    end

    if url ~= "" and entry_url ~= "" and url == entry_url then
      return entry, "url"
    end

    if file_value ~= "" and M.field(entry, "file") ~= "" then
      for _, item in ipairs(parse_file_field_items(M.field(entry, "file"))) do
        if normalize_file_path(zotero_file_candidate(item)) == normalize_file_path(file_value) then
          return entry, "file"
        end
      end
    end
  end

  return nil, nil
end

function M.append_entry(entry_text, opts)
  entry_text = trim(entry_text or "")
  if entry_text == "" then
    return nil, "empty BibTeX entry"
  end

  local path = (opts and opts.bib_path) or M.bib_path(opts and opts.wiki_root)
  local lines = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}
  if #lines > 0 and trim(lines[#lines]) ~= "" then
    lines[#lines + 1] = ""
  end
  vim.list_extend(lines, split_lines(entry_text))

  local ok, err = pcall(vim.fn.writefile, lines, path)
  if not ok then
    return nil, tostring(err)
  end
  return true, nil
end

function M.set_entry_field(key, field_name, value, opts)
  field_name = trim(field_name or "")
  if field_name == "" then
    return nil, "missing field name"
  end

  local path = (opts and opts.bib_path) or M.bib_path(opts and opts.wiki_root)
  local lines = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or nil
  if not lines then
    return nil, "ref.bib is not readable"
  end

  local entry = M.find_entry_by_key(key, { bib_path = path })
  if not entry then
    return nil, "no entry found for @" .. key
  end

  local field_pattern = "^%s*" .. vim.pesc(field_name) .. "%s*="
  local replacement = "  " .. field_name .. " = {" .. bib_escape(value) .. "},"
  for i = entry.start_line + 1, entry.end_line - 1 do
    if lines[i] and lines[i]:lower():match(field_pattern:lower()) then
      local indent = lines[i]:match("^(%s*)") or "  "
      lines[i] = indent .. field_name .. " = {" .. bib_escape(value) .. "},"
      local ok, err = pcall(vim.fn.writefile, lines, path)
      if not ok then
        return nil, tostring(err)
      end
      return true, nil
    end
  end

  local prev = entry.end_line - 1
  while prev > entry.start_line and trim(lines[prev] or "") == "" do
    prev = prev - 1
  end
  if prev > entry.start_line and lines[prev] and not lines[prev]:match(",%s*$") then
    lines[prev] = lines[prev] .. ","
  end

  table.insert(lines, entry.end_line, replacement)
  local ok, err = pcall(vim.fn.writefile, lines, path)
  if not ok then
    return nil, tostring(err)
  end
  return true, nil
end

local stopwords = {
  a = true,
  an = true,
  ["and"] = true,
  ["for"] = true,
  ["in"] = true,
  of = true,
  on = true,
  the = true,
  to = true,
  with = true,
}

function M.slug(value, opts)
  opts = opts or {}
  local max_words = opts.max_words or 6
  local separator = opts.separator or ""
  local words = {}

  value = (value or ""):lower():gsub("['’]", ""):gsub("[^%w]+", " ")
  for word in value:gmatch("[%w]+") do
    if not stopwords[word] or #words == 0 then
      words[#words + 1] = word
    end
    if #words >= max_words then
      break
    end
  end

  return table.concat(words, separator)
end

local function short_hash(value)
  local hash = 5381
  for i = 1, #(value or "") do
    hash = (hash * 33 + value:byte(i)) % 0x1000000
  end
  return string.format("%06x", hash)
end

function M.derive_key(opts)
  opts = opts or {}
  local candidates = {}
  if trim(opts.title or "") ~= "" then
    candidates[#candidates + 1] = opts.title
  end
  if trim(opts.file or "") ~= "" then
    candidates[#candidates + 1] = vim.fn.fnamemodify(opts.file, ":t:r")
  end
  if trim(opts.url or "") ~= "" then
    candidates[#candidates + 1] = opts.url
  end

  local stem = ""
  for _, candidate in ipairs(candidates) do
    stem = M.slug(candidate or "", { max_words = 7 })
    if stem ~= "" then
      break
    end
  end
  if stem == "" then
    stem = "paper" .. short_hash(table.concat({ opts.title or "", opts.file or "", opts.url or "" }, ":"))
  end
  if stem:match("^%d") then
    stem = "paper" .. stem
  end
  if #stem > 60 then
    stem = stem:sub(1, 60)
  end
  return stem .. tostring(opts.year or os.date("%Y"))
end

function M.slugify_filename(filename)
  filename = trim(filename or "")
  local name = vim.fn.fnamemodify(filename, ":t:r")
  local ext = vim.fn.fnamemodify(filename, ":e")
  local slug = M.slug(name, { max_words = 12, separator = "-" })
  if slug == "" then
    slug = "paper"
  end
  if ext ~= "" then
    return slug .. "." .. ext:lower()
  end
  return slug
end

function M.render_entry(opts)
  opts = opts or {}
  local entry_type = opts.type or "misc"
  local key = opts.key or M.derive_key(opts)
  local fields = opts.fields or {}
  local order = {
    "title",
    "author",
    "year",
    "journal",
    "booktitle",
    "eprint",
    "archivePrefix",
    "primaryClass",
    "doi",
    "url",
    "howpublished",
    "file",
  }
  local emitted = {}
  local lines = { "@" .. entry_type .. "{" .. key .. "," }

  local function emit(name)
    local value = fields[name] or fields[name:lower()]
    if value ~= nil and trim(tostring(value)) ~= "" then
      lines[#lines + 1] = "  " .. name .. " = {" .. bib_escape(tostring(value)) .. "},"
      emitted[name:lower()] = true
    end
  end

  for _, name in ipairs(order) do
    emit(name)
  end
  for name, value in pairs(fields) do
    if not emitted[name:lower()] and trim(tostring(value)) ~= "" then
      emit(name)
    end
  end

  lines[#lines + 1] = "}"
  return table.concat(lines, "\n")
end

function M.source_key_from_content(content)
  local line = (content or ""):match("^%s*([^\n]*)") or ""
  local key = line:match("^%s*Source:%s*@([^%s,;%)%]]+)")
  return key and key:gsub("%.$", "") or nil
end

function M.find_source_notes(key, opts)
  key = trim((key or ""):gsub("^@", ""))
  local root = M.wiki_root(opts and opts.wiki_root)
  local note_dir = join_paths(root, "note")
  local matches = {}
  if key == "" or vim.fn.isdirectory(note_dir) == 0 then
    return matches
  end

  for _, note_path in ipairs(vim.fn.globpath(note_dir, "*.typ", false, true)) do
    if vim.fn.filereadable(note_path) == 1 then
      for lnum, line in ipairs(vim.fn.readfile(note_path)) do
        if M.source_key_from_content(line) == key then
          matches[#matches + 1] = {
            path = note_path,
            lnum = lnum,
            key = key,
            id = note_path:match("note/(%d+)%.typ$"),
          }
          break
        end
      end
    end
  end
  return matches
end

function M.open_ref_entry(key, opts)
  local root = M.wiki_root(opts and opts.wiki_root)
  local path = (opts and opts.bib_path) or M.bib_path(root)
  local entry = M.find_entry_by_key(key, { bib_path = path })
  vim.cmd("cd " .. vim.fn.fnameescape(root))
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  if entry then
    vim.api.nvim_win_set_cursor(0, { entry.start_line, 0 })
  end
end

function M.open_source_or_entry(key, opts)
  key = trim((key or ""):gsub("^@", ""))
  if key == "" then
    return
  end
  local root = M.wiki_root(opts and opts.wiki_root)
  local matches = M.find_source_notes(key, { wiki_root = root })

  local function open_match(match)
    vim.cmd("cd " .. vim.fn.fnameescape(root))
    vim.cmd("edit " .. vim.fn.fnameescape(match.path))
    vim.api.nvim_win_set_cursor(0, { match.lnum or 1, 0 })
  end

  if #matches == 1 then
    open_match(matches[1])
    return
  end

  if #matches > 1 then
    vim.ui.select(matches, {
      prompt = "Multiple paper notes for @" .. key,
      format_item = function(item)
        return string.format("%s  %s", item.id or vim.fn.fnamemodify(item.path, ":t"), item.path)
      end,
    }, function(choice)
      if choice then
        open_match(choice)
      end
    end)
    return
  end

  vim.notify("ref.bib has @" .. key .. ", but no `Source: @" .. key .. "` note was found", vim.log.levels.WARN)
  M.open_ref_entry(key, { wiki_root = root })
end

function M.resolve_asset_path(path, opts)
  path = trim(path or "")
  if path == "" then
    return nil
  end
  if path:match("^%a[%w+.-]*://") then
    return path
  end
  if path:sub(1, 1) == "~" then
    return vim.fn.expand(path)
  end
  if path:sub(1, 1) == "/" then
    return path
  end
  return join_paths(M.wiki_root(opts and opts.wiki_root), path)
end

function M.find_assets_for_key(key, opts)
  local entry = M.find_entry_by_key(key, opts)
  if not entry then
    return nil
  end

  local file_field = M.field(entry, "file")
  return {
    entry = entry,
    pdf_path = M.resolve_asset_path(extract_file_by_ext(file_field, { "pdf" }), opts),
    html_path = M.resolve_asset_path(extract_file_by_ext(file_field, { "html", "htm" }), opts),
    url = M.field(entry, "url") ~= "" and M.field(entry, "url") or M.field(entry, "howpublished"),
  }
end

function M.entry_primary_source(entry, opts)
  if not entry then
    return ""
  end
  local file_field = M.field(entry, "file")
  local file = extract_file_by_ext(file_field, { "pdf", "html", "htm" })
  if file and file ~= "" then
    return file
  end
  return M.field(entry, "url") ~= "" and M.field(entry, "url") or M.field(entry, "howpublished")
end

function M.clean_title(title)
  return collapse_ws((title or ""):gsub("[{}]", ""))
end

return M
