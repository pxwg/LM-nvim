local M = {}
local zk_bib = require("util.zk_bib")

local function wiki_root()
  return vim.fn.expand("~/wiki")
end

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

local function split_csv(value)
  local items = {}
  for part in (value or ""):gmatch("([^,]+)") do
    local item = trim(part)
    if item ~= "" then
      items[#items + 1] = item
    end
  end
  return items
end

local function split_words(value)
  local items = {}
  local seen = {}
  for part in (value or ""):gmatch("([^,;|]+)") do
    local item = collapse_ws(part)
    if item ~= "" then
      local key = item:lower()
      if not seen[key] then
        seen[key] = true
        items[#items + 1] = item
      end
    end
  end
  return items
end

local function basename(path)
  return (path or ""):match("([^/]+)$") or (path or "")
end

local function join_paths(...)
  local path = table.concat({ ... }, "/"):gsub("//+", "/")
  return path
end

local function deep_copy(value)
  if type(value) ~= "table" then
    return value
  end
  return vim.deepcopy(value)
end

local function is_list(value)
  return type(value) == "table" and vim.islist(value)
end

local function has_value(value)
  if value == nil then
    return false
  end
  if type(value) == "string" then
    return trim(value) ~= ""
  end
  if type(value) == "table" then
    return next(value) ~= nil
  end
  return true
end

local function set_path(tbl, path, value)
  local current = tbl
  for i = 1, #path - 1 do
    local key = path[i]
    if type(current[key]) ~= "table" then
      current[key] = {}
    end
    current = current[key]
  end
  current[path[#path]] = value
end

local function clear_path(tbl, path)
  local current = tbl
  for i = 1, #path - 1 do
    local key = path[i]
    if type(current) ~= "table" then
      return
    end
    current = current[key]
    if current == nil then
      return
    end
  end
  if type(current) == "table" then
    current[path[#path]] = nil
  end
end

local function get_path(tbl, path)
  local current = tbl
  for _, key in ipairs(path) do
    if type(current) ~= "table" then
      return nil
    end
    current = current[key]
    if current == nil then
      return nil
    end
  end
  return current
end

local function iter_paths(tbl, callback, path)
  path = path or {}
  if type(tbl) ~= "table" then
    callback(path, tbl)
    return
  end

  if is_list(tbl) then
    callback(path, tbl)
    return
  end

  local had_entry = false
  for key, value in pairs(tbl) do
    had_entry = true
    local next_path = vim.list_extend(deep_copy(path), { key })
    iter_paths(value, callback, next_path)
  end

  if not had_entry then
    callback(path, tbl)
  end
end

local function merge_missing(target, source, user)
  if type(source) ~= "table" then
    return target
  end

  iter_paths(source, function(path, value)
    if #path == 0 then
      return
    end
    if has_value(get_path(user, path)) then
      return
    end
    if has_value(get_path(target, path)) then
      return
    end
    set_path(target, path, deep_copy(value))
  end)

  return target
end

local function merge_override(target, source, user)
  if type(source) ~= "table" then
    return target
  end

  iter_paths(source, function(path, value)
    if #path == 0 then
      return
    end
    if has_value(get_path(user, path)) then
      return
    end
    set_path(target, path, deep_copy(value))
  end)

  return target
end

local function toml_escape(value)
  return (value or ""):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")
end

local function toml_literal(value)
  local value_type = type(value)
  if value_type == "boolean" then
    return value and "true" or "false"
  end

  if value_type == "number" then
    return tostring(value)
  end

  if is_list(value) then
    local items = {}
    for _, item in ipairs(value) do
      items[#items + 1] = toml_literal(item)
    end
    return "[" .. table.concat(items, ", ") .. "]"
  end

  return string.format('"%s"', toml_escape(value or ""))
end

local function flatten_metadata(tbl, prefix, out)
  out = out or {}
  prefix = prefix or {}

  for key, value in pairs(tbl or {}) do
    local path = vim.list_extend(deep_copy(prefix), { key })
    if type(value) == "table" and not is_list(value) then
      flatten_metadata(value, path, out)
    else
      if table.concat(path, ".") ~= "user.source-kind" then
        out[#out + 1] = {
          key = table.concat(path, "."),
          value = value,
        }
      end
    end
  end

  table.sort(out, function(a, b)
    return a.key < b.key
  end)
  return out
end

local function toml_key_order(keys)
  local preferred = {
    ["schema-version"] = 1,
    aliases = 2,
    abstract = 3,
    keywords = 4,
    generated = 5,
    ["checklist-status"] = 6,
    relation = 7,
    ["relation-target"] = 8,
    user = 100,
  }

  table.sort(keys, function(a, b)
    local pa = preferred[a] or 1000
    local pb = preferred[b] or 1000
    if pa ~= pb then
      return pa < pb
    end
    return a < b
  end)
end

local function render_toml_table(tbl, prefix, lines)
  prefix = prefix or {}
  lines = lines or {}

  local scalars = {}
  local tables = {}
  for key, value in pairs(tbl or {}) do
    local full_key = #prefix > 0 and (table.concat(prefix, ".") .. "." .. key) or key
    if full_key ~= "user.source-kind" then
      if type(value) == "table" and not is_list(value) then
        tables[#tables + 1] = key
      else
        scalars[#scalars + 1] = key
      end
    end
  end

  toml_key_order(scalars)
  table.sort(tables)

  if #prefix > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "[" .. table.concat(prefix, ".") .. "]"
  end

  for _, key in ipairs(scalars) do
    lines[#lines + 1] = key .. " = " .. toml_literal(tbl[key])
  end

  for _, key in ipairs(tables) do
    render_toml_table(tbl[key], vim.list_extend(deep_copy(prefix), { key }), lines)
  end

  return lines
end

local function render_metadata_lines(metadata)
  metadata = deep_copy(metadata or {})
  if metadata["schema-version"] == nil then
    metadata["schema-version"] = 1
  end

  local lines = {
    "#let zk-metadata = toml(bytes(",
    "  ```toml",
  }

  for _, line in ipairs(render_toml_table(metadata)) do
    lines[#lines + 1] = "  " .. line
  end

  lines[#lines + 1] = "  ```.text,"
  lines[#lines + 1] = "))"
  return lines
end

local function decode_html_entities(value)
  if type(value) ~= "string" then
    return ""
  end

  local entities = {
    amp = "&",
    lt = "<",
    gt = ">",
    quot = '"',
    apos = "'",
    nbsp = " ",
  }

  value = value:gsub("&(#x%x+);", function(hex)
    local code = tonumber(hex:sub(3), 16)
    return code and vim.fn.nr2char(code) or hex
  end)
  value = value:gsub("&(#%d+);", function(dec)
    local code = tonumber(dec:sub(2), 10)
    return code and vim.fn.nr2char(code) or dec
  end)
  value = value:gsub("&([%a]+);", function(name)
    return entities[name] or ("&" .. name .. ";")
  end)
  return value
end

local function strip_tags(value)
  return collapse_ws(decode_html_entities((value or ""):gsub("<[^>]+>", " ")))
end

local function normalize_url(url)
  url = trim(url)
  if url == "" then
    return ""
  end
  if url:match("^https?://") then
    return url
  end
  return "https://" .. url
end

local function infer_title_from_url(url)
  local path = normalize_url(url):match("^https?://[^/]+/(.*)$") or ""
  local slug = path:match("([^/?#]+)") or ""
  slug = slug:gsub("%.[%a%d]+$", ""):gsub("[-_]+", " ")
  return collapse_ws(slug:gsub("^%l", string.upper))
end

local function extract_meta_content(html, attr_name, attr_value)
  for _, quote in ipairs({ '"', "'" }) do
    local pattern = "<meta[^>]-"
      .. attr_name
      .. "%s*=%s*"
      .. quote
      .. attr_value
      .. quote
      .. "[^>]-content%s*=%s*"
      .. quote
    local content = html:match(pattern .. "(.-)" .. quote)
    if content and content ~= "" then
      return strip_tags(content)
    end
  end

  for _, quote in ipairs({ '"', "'" }) do
    local pattern = "<meta[^>]-content%s*=%s*" .. quote .. "(.-)" .. quote .. "[^>]-" .. attr_name .. "%s*=%s*" .. quote
    local content = html:match(pattern .. attr_value .. quote)
    if content and content ~= "" then
      return strip_tags(content)
    end
  end

  return ""
end

local function extract_meta_field(html, name)
  local direct = extract_meta_content(html, "name", name)
  if direct ~= "" then
    return direct
  end
  return extract_meta_content(html, "property", name)
end

local function extract_arxiv_id(url)
  local normalized = normalize_url(url)
  return normalized:match("arxiv%.org/abs/([^?#/]+)")
    or normalized:match("arxiv%.org/pdf/([^?#/]+)%.pdf")
    or normalized:match("^arxiv:(.+)$")
end

local function canonical_arxiv_abs_url(url)
  local arxiv_id = extract_arxiv_id(url)
  if not arxiv_id then
    return normalize_url(url)
  end
  return "https://arxiv.org/abs/" .. arxiv_id
end

local function extract_inspire_id(url)
  return normalize_url(url):match("inspirehep%.net/literature/(%d+)")
end

local function system_text(cmd)
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    return nil, collapse_ws(result.stderr or "")
  end
  return result.stdout or "", nil
end

local function fetch_url(url)
  return system_text({
    "curl",
    "-L",
    "--max-time",
    "8",
    "--connect-timeout",
    "4",
    "-A",
    "Mozilla/5.0 (compatible; zk-capture/1.0)",
    url,
  })
end

local function fetch_url_metadata(url)
  url = normalize_url(url)
  if url == "" then
    return nil, "Missing URL"
  end

  local html, err = fetch_url(url)
  if not html or html == "" then
    return nil, err ~= "" and err or "Empty response body"
  end

  local title = strip_tags(html:match("<title[^>]*>(.-)</title>"))
  local og_title = extract_meta_content(html, "property", "og:title")
  local twitter_title = extract_meta_content(html, "name", "twitter:title")
  local description = extract_meta_content(html, "name", "description")
  if description == "" then
    description = extract_meta_content(html, "property", "og:description")
  end
  if description == "" then
    description = extract_meta_content(html, "name", "twitter:description")
  end

  local keywords = extract_meta_content(html, "name", "keywords")

  return {
    url = url,
    title = og_title ~= "" and og_title or (twitter_title ~= "" and twitter_title or title),
    abstract = description,
    keywords = split_words(keywords),
  }
end

local function fetch_inspire_record_json_by_id(record_id)
  local raw, err = system_text({
    "curl",
    "-L",
    "--max-time",
    "8",
    "--connect-timeout",
    "4",
    "https://inspirehep.net/api/literature/" .. record_id,
  })
  if not raw or raw == "" then
    return nil, err ~= "" and err or "Empty INSPIRE response"
  end

  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok then
    return nil, "Failed to decode INSPIRE JSON"
  end
  return decoded, nil
end

local function fetch_inspire_record_json_by_arxiv(arxiv_id)
  local raw, err = system_text({
    "curl",
    "-L",
    "--max-time",
    "8",
    "--connect-timeout",
    "4",
    "https://inspirehep.net/api/literature?q=arxiv:" .. arxiv_id .. "&size=1",
  })
  if not raw or raw == "" then
    return nil, err ~= "" and err or "Empty INSPIRE response"
  end

  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok then
    return nil, "Failed to decode INSPIRE JSON"
  end

  local hits = decoded.hits and decoded.hits.hits or {}
  if #hits == 0 then
    return nil, "No INSPIRE record for arXiv id"
  end
  return hits[1], nil
end

local function fetch_inspire_bibtex(url)
  local record_id = extract_inspire_id(url)
  if record_id then
    return system_text({
      "curl",
      "-L",
      "--max-time",
      "8",
      "--connect-timeout",
      "4",
      "https://inspirehep.net/api/literature/" .. record_id,
      "-H",
      "Accept: application/x-bibtex",
    })
  end

  local arxiv_id = extract_arxiv_id(url)
  if arxiv_id then
    return system_text({
      "curl",
      "-L",
      "--max-time",
      "8",
      "--connect-timeout",
      "4",
      "https://inspirehep.net/api/literature?q=arxiv:" .. arxiv_id .. "&size=1&format=bibtex",
    })
  end

  return nil, "Unsupported INSPIRE/arXiv source"
end

local function parse_arxiv_subjects(html)
  local subjects = {}
  local seen = {}

  local block = html:match('<span class="primary%-subject">(.-)</span>(.-)</td>')
    or html:match('<td class="tablecell comments subjects">.-<span class="primary%-subject">(.-)</span>(.-)</td>')

  local combined = ""
  if block then
    if type(block) == "string" then
      combined = strip_tags(block)
    elseif type(block) == "table" then
      combined = strip_tags(table.concat(block, " "))
    end
  else
    combined = strip_tags(html:match('<td class="tablecell comments subjects">(.-)</td>') or "")
  end

  for _, item in ipairs(split_words(combined:gsub("%(", ","):gsub("%)", ","))) do
    local key = item:lower()
    if item ~= "" and not seen[key] then
      seen[key] = true
      subjects[#subjects + 1] = item
    end
  end
  return subjects
end

local function parse_arxiv_authors(html)
  local authors = {}
  for author in html:gmatch('<meta%s+name="citation_author"%s+content="(.-)"') do
    authors[#authors + 1] = strip_tags(author)
  end
  if #authors == 0 then
    local block = html:match('<div class="authors">(.-)</div>') or ""
    for author in block:gmatch("<a[^>]*>(.-)</a>") do
      authors[#authors + 1] = strip_tags(author)
    end
  end
  return authors
end

local function build_arxiv_bibtex_key(title, authors, year)
  local surname = ""
  if type(authors) == "table" and authors[1] then
    surname = authors[1]:match("([%w%-]+)%s*$") or authors[1]
    surname = surname:lower():gsub("[^%w]+", "")
  end

  local words = {}
  for word in collapse_ws(title):lower():gmatch("[%w]+") do
    if #words >= 6 then
      break
    end
    words[#words + 1] = word
  end

  local stem = table.concat(words, "")
  if surname == "" then
    surname = "arxiv"
  end
  if stem == "" then
    stem = "paper"
  end
  return surname .. tostring(year or os.date("%Y")) .. stem
end

local function render_arxiv_bibtex(data)
  local authors = data.authors or {}
  local author_text = table.concat(authors, " and ")
  local key = build_arxiv_bibtex_key(data.title or "", authors, data.year)
  local lines = {
    "@misc{" .. key .. ",",
    "      title={" .. (data.title or "") .. "}, ",
    "      author={" .. author_text .. "},",
    "      year={" .. tostring(data.year or "") .. "},",
    "      eprint={" .. (data.eprint or "") .. "},",
    "      archivePrefix={arXiv},",
  }

  if trim(data.primary_class or "") ~= "" then
    lines[#lines + 1] = "      primaryClass={" .. data.primary_class .. "},"
  end
  lines[#lines + 1] = "      url={" .. (data.url or "") .. "}, "
  lines[#lines + 1] = "}"
  return table.concat(lines, "\n")
end

local function fetch_arxiv_abs_data(url)
  local abs_url = canonical_arxiv_abs_url(url)
  local html, err = fetch_url(abs_url)
  if not html or html == "" then
    return nil, err ~= "" and err or "Empty arXiv response"
  end

  local arxiv_id = extract_arxiv_id(abs_url) or ""
  local title = extract_meta_field(html, "citation_title")
  if title == "" then
    title = strip_tags(html:match('<h1 class="title mathjax">(.-)</h1>') or "")
    title = title:gsub("^Title:%s*", "")
  end

  local abstract = extract_meta_field(html, "citation_abstract")
  if abstract == "" then
    abstract = strip_tags(html:match('<blockquote class="abstract mathjax">(.-)</blockquote>') or "")
    abstract = abstract:gsub("^Abstract:%s*", "")
  end
  if abstract == "" then
    abstract = extract_meta_field(html, "og:description")
  end
  if abstract == "" then
    abstract = extract_meta_field(html, "twitter:description")
  end
  if abstract == "" then
    abstract = extract_meta_field(html, "description")
  end

  local keywords = parse_arxiv_subjects(html)
  local authors = parse_arxiv_authors(html)
  local year = tonumber((html:match("arXiv:" .. vim.pesc(arxiv_id) .. "v%d+.-(%d%d%d%d)") or ""))
  if not year then
    year = tonumber((extract_meta_field(html, "citation_date"):match("^(%d%d%d%d)") or ""))
  end

  local primary_class = html:match("arXiv:" .. vim.pesc(arxiv_id) .. "v%d+%s*%[([^%]]+)%]") or ""
  if primary_class == "" then
    primary_class = collapse_ws(html:match('<span class="primary%-subject">(.-)</span>') or "")
  end

  local bibtex = render_arxiv_bibtex({
    title = title,
    authors = authors,
    year = year,
    eprint = arxiv_id,
    primary_class = primary_class,
    url = abs_url,
  })

  return {
    source = abs_url,
    title = title,
    abstract = abstract,
    keywords = keywords,
    bibtex = bibtex,
  },
    nil
end

local function metadata_from_inspire_record(record)
  local metadata = record and record.metadata or {}
  local title = ""
  if type(metadata.titles) == "table" and metadata.titles[1] then
    title = collapse_ws(metadata.titles[1].title or "")
  end

  local abstract = ""
  if type(metadata.abstracts) == "table" and metadata.abstracts[1] then
    abstract = collapse_ws(metadata.abstracts[1].value or "")
  end

  local keywords = {}
  local seen = {}
  for _, subject in ipairs(metadata.inspire_categories or {}) do
    local term = collapse_ws(subject.term or "")
    if term ~= "" and not seen[term:lower()] then
      seen[term:lower()] = true
      keywords[#keywords + 1] = term
    end
  end

  return {
    title = title,
    abstract = abstract,
    keywords = keywords,
  }
end

local function fetch_paper_web_data(url)
  local normalized = normalize_url(url)
  local arxiv_id = extract_arxiv_id(normalized)
  local inspire_id = extract_inspire_id(normalized)

  if inspire_id then
    local record, err
    record, err = fetch_inspire_record_json_by_id(inspire_id)

    local info = record and metadata_from_inspire_record(record) or {}
    local bibtex, bib_err = fetch_inspire_bibtex(normalized)
    bibtex = trim(bibtex or "")

    if record or bibtex ~= "" then
      return {
        source = normalized,
        title = info.title or "",
        abstract = info.abstract or "",
        keywords = info.keywords or {},
        bibtex = bibtex,
      },
        (err and err ~= "" and err) or (bib_err and bib_err ~= "" and bib_err) or nil
    end
  end

  if arxiv_id then
    local arxiv, arxiv_err = fetch_arxiv_abs_data(normalized)
    local inspire_record, inspire_err = fetch_inspire_record_json_by_arxiv(arxiv_id)
    local inspire_info = inspire_record and metadata_from_inspire_record(inspire_record) or {}
    local inspire_bibtex, bib_err = fetch_inspire_bibtex(normalized)
    inspire_bibtex = trim(inspire_bibtex or "")

    if arxiv then
      return {
        source = arxiv.source,
        title = arxiv.title,
        abstract = arxiv.abstract ~= "" and arxiv.abstract or (inspire_info.abstract or ""),
        keywords = (#arxiv.keywords > 0) and arxiv.keywords or (inspire_info.keywords or {}),
        bibtex = inspire_bibtex ~= "" and inspire_bibtex or arxiv.bibtex,
      },
        (arxiv_err and arxiv_err ~= "" and arxiv_err)
          or (inspire_err and inspire_err ~= "" and inspire_err)
          or (bib_err and bib_err ~= "" and bib_err)
          or nil
    end
  end

  local generic, err = fetch_url_metadata(normalized)
  if not generic then
    return nil, err
  end

  return {
    source = generic.url,
    title = generic.title,
    abstract = generic.abstract,
    keywords = generic.keywords,
    bibtex = "",
  },
    nil
end

local function command_exists(name)
  return vim.fn.executable(name) == 1
end

local function parse_pdfinfo_output(text)
  local data = {}
  for line in (text or ""):gmatch("[^\n]+") do
    local key, value = line:match("^([^:]+):%s*(.*)$")
    if key and value then
      data[trim(key)] = trim(value)
    end
  end
  return data
end

local function clean_pdf_metadata_value(value)
  value = collapse_ws(value or "")
  local lower = value:lower()
  if lower == "" or lower == "(null)" or lower == "null" or lower == "untitled" or lower == "unknown" then
    return ""
  end
  return value
end

local function fetch_pdf_metadata(path)
  local info = {
    title = "",
    abstract = "",
    keywords = {},
  }

  if command_exists("pdfinfo") then
    local raw = system_text({ "pdfinfo", path })
    if raw then
      local parsed = parse_pdfinfo_output(raw)
      info.title = clean_pdf_metadata_value(parsed.Title)
      info.abstract = clean_pdf_metadata_value(parsed.Subject)
      if trim(parsed.Keywords or "") ~= "" then
        info.keywords = split_words(parsed.Keywords)
      end
    end
  end

  if info.title == "" and command_exists("mdls") then
    local raw = system_text({ "mdls", "-raw", "-name", "kMDItemTitle", path })
    if raw then
      info.title = clean_pdf_metadata_value(raw:gsub('^"(.*)"%s*$', "%1"))
    end
  end

  return info
end

local function curl_text(url, headers)
  local cmd = {
    "curl",
    "-L",
    "--max-time",
    "6",
    "--connect-timeout",
    "3",
    "-A",
    "Mozilla/5.0 (compatible; zk-capture/1.0)",
  }

  for _, header in ipairs(headers or {}) do
    cmd[#cmd + 1] = "-H"
    cmd[#cmd + 1] = header
  end

  cmd[#cmd + 1] = url
  return system_text(cmd)
end

local function looks_like_bibtex(text)
  text = trim(text or "")
  if text:match("^@[%a][%w%-]*%s*[%{%(%[]") then
    return text
  end
  return ""
end

local function url_encode(value)
  return tostring(value or ""):gsub("\n", " "):gsub("([^%w%-_%.~])", function(ch)
    return string.format("%%%02X", string.byte(ch))
  end)
end

local function url_encode_path(value)
  return url_encode(value):gsub("%%2F", "/")
end

local function normalize_doi_candidate(value)
  value = trim(value or "")
  value = value:gsub("^[Dd][Oo][Ii]:%s*", "")
  value = value:gsub("^https?://dx%.doi%.org/", "")
  value = value:gsub("^https?://doi%.org/", "")
  value = value:gsub("[,%s%)%]%}>%.;:]+$", "")
  return value
end

local function extract_doi_from_text(text)
  for candidate in (text or ""):gmatch("10%.%d%d%d%d%d?%d?%d?%d?%d?/%S+") do
    local doi = normalize_doi_candidate(candidate)
    if doi:match("^10%.%d%d%d%d") then
      return doi
    end
  end
  return ""
end

local function extract_arxiv_id_from_text(text)
  text = text or ""
  local id = text:match("[Aa][Rr][Xx][Ii][Vv]:%s*([%a%-]+/%d%d%d%d%d%d%d+v?%d*)")
    or text:match("[Aa][Rr][Xx][Ii][Vv]:%s*(%d%d%d%d%.%d%d%d%d%d+v?%d*)")
    or text:match("arxiv%.org/abs/([^%s%)%]%}]+)")
    or text:match("arxiv%.org/pdf/([^%s%)%]%}]+)%.pdf")

  if not id or id == "" then
    return ""
  end
  return id:gsub("[,%s%)%]%}>%.;:]+$", "")
end

local function fetch_pdf_probe_text(path)
  local chunks = { basename(path) }

  if command_exists("pdfinfo") then
    local meta = system_text({ "pdfinfo", "-meta", path })
    if meta and trim(meta) ~= "" then
      chunks[#chunks + 1] = meta
    end
  end

  if command_exists("pdftotext") then
    local text = system_text({ "pdftotext", "-f", "1", "-l", "3", "-layout", path, "-" })
    if text and trim(text) ~= "" then
      chunks[#chunks + 1] = text
    end
  end

  if command_exists("mutool") then
    local text = system_text({ "mutool", "draw", "-F", "txt", "-o", "-", path, "1-3" })
    if text and trim(text) ~= "" then
      chunks[#chunks + 1] = text
    end
  end

  if command_exists("strings") then
    local text = system_text({ "sh", "-c", 'strings -n 8 "$1" | head -300', "sh", path })
    if text and trim(text) ~= "" then
      chunks[#chunks + 1] = text
    end
  end

  return table.concat(chunks, "\n")
end

local function infer_pdf_title_from_text(text)
  for line in (text or ""):gmatch("[^\n]+") do
    line = collapse_ws(line)
    local lower = line:lower()
    if
      #line >= 16
      and #line <= 220
      and not lower:match("^abstract")
      and not lower:match("^keywords")
      and not lower:match("^doi")
      and not lower:match("^arxiv")
      and not lower:match("^journal")
      and not lower:match("^submitted")
      and not line:match("^%d+$")
      and not line:match("^https?://")
    then
      return line
    end
  end
  return ""
end

local title_stopwords = {
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

local function title_tokens(title)
  local tokens = {}
  local count = 0
  for word in (title or ""):lower():gsub("[{}]", " "):gmatch("[%w]+") do
    if #word > 2 and not title_stopwords[word] and not tokens[word] then
      tokens[word] = true
      count = count + 1
    end
  end
  return tokens, count
end

local function title_similarity(a, b)
  local left, left_count = title_tokens(a)
  local right, right_count = title_tokens(b)
  if left_count == 0 or right_count == 0 then
    return 0
  end

  local shared = 0
  for token in pairs(left) do
    if right[token] then
      shared = shared + 1
    end
  end
  return shared / math.max(left_count, right_count)
end

local function decode_json(raw)
  local ok, decoded = pcall(vim.json.decode, raw or "")
  if ok then
    return decoded
  end
  return nil
end

local function result_from_bibtex(bibtex, method, source)
  bibtex = looks_like_bibtex(bibtex)
  if bibtex == "" then
    return nil
  end

  local entry = zk_bib.parse_entry(bibtex)
  if not entry or trim(entry.key or "") == "" then
    return nil
  end

  return {
    bibtex = bibtex,
    method = method,
    source = source,
    title = zk_bib.clean_title(zk_bib.field(entry, "title")),
    abstract = zk_bib.field(entry, "abstract"),
    keywords = split_words(zk_bib.field(entry, "keywords")),
    entry = entry,
  }
end

local function fetch_bibtex_by_doi(doi)
  doi = normalize_doi_candidate(doi)
  if doi == "" then
    return nil
  end

  local attempts = {
    {
      method = "INSPIRE DOI",
      url = "https://inspirehep.net/api/literature?q=doi:" .. url_encode(doi) .. "&size=1&format=bibtex",
    },
    {
      method = "DOI content negotiation",
      url = "https://doi.org/" .. url_encode_path(doi),
      headers = { "Accept: application/x-bibtex" },
    },
    {
      method = "Crossref DOI transform",
      url = "https://api.crossref.org/works/" .. url_encode_path(doi) .. "/transform/application/x-bibtex",
    },
    {
      method = "CrossCite DOI transform",
      url = "https://data.crosscite.org/application/x-bibtex/" .. url_encode_path(doi),
    },
  }

  for _, attempt in ipairs(attempts) do
    local raw = curl_text(attempt.url, attempt.headers)
    local result = result_from_bibtex(raw, attempt.method, "https://doi.org/" .. doi)
    if result then
      return result
    end
  end

  return nil
end

local function render_authors(authors)
  local rendered = {}
  for _, author in ipairs(authors or {}) do
    if type(author) == "string" then
      rendered[#rendered + 1] = author
    elseif author.name then
      rendered[#rendered + 1] = author.name
    else
      local given = author.given or ""
      local family = author.family or ""
      local name = collapse_ws(given .. " " .. family)
      if name ~= "" then
        rendered[#rendered + 1] = name
      end
    end
  end
  return table.concat(rendered, " and ")
end

local function render_crossref_entry(item)
  local title = type(item.title) == "table" and item.title[1] or item.title or ""
  local year = nil
  local parts = item.issued and item.issued["date-parts"]
  if type(parts) == "table" and parts[1] then
    year = parts[1][1]
  end
  return zk_bib.render_entry({
    type = item.type == "journal-article" and "article" or "misc",
    key = zk_bib.derive_key({ title = title, year = year }),
    fields = {
      title = title,
      author = render_authors(item.author),
      year = year,
      journal = type(item["container-title"]) == "table" and item["container-title"][1] or "",
      doi = item.DOI,
      url = item.URL,
    },
  })
end

local function fetch_crossref_by_title(title)
  if #trim(title) < 12 then
    return nil
  end

  local raw = curl_text("https://api.crossref.org/works?rows=5&query.title=" .. url_encode(title))
  local decoded = decode_json(raw)
  local items = decoded and decoded.message and decoded.message.items or {}

  for _, item in ipairs(items) do
    local candidate_title = type(item.title) == "table" and item.title[1] or item.title or ""
    if title_similarity(title, candidate_title) >= 0.45 then
      local result = item.DOI and fetch_bibtex_by_doi(item.DOI) or nil
      if result then
        result.method = "Crossref title -> " .. result.method
        return result
      end
      return result_from_bibtex(render_crossref_entry(item), "Crossref title", item.URL)
    end
  end

  return nil
end

local function render_semantic_scholar_entry(item)
  local external = item.externalIds or {}
  return zk_bib.render_entry({
    type = "article",
    key = zk_bib.derive_key({ title = item.title, year = item.year }),
    fields = {
      title = item.title,
      author = render_authors(item.authors),
      year = item.year,
      journal = item.venue,
      doi = external.DOI,
      eprint = external.ArXiv,
      archivePrefix = external.ArXiv and "arXiv" or "",
      url = item.url,
    },
  })
end

local function fetch_semantic_scholar_by_title(title)
  if #trim(title) < 12 then
    return nil
  end

  local url = "https://api.semanticscholar.org/graph/v1/paper/search?limit=5&fields="
    .. "title,authors,year,venue,externalIds,url&query="
    .. url_encode(title)
  local raw = curl_text(url)
  local decoded = decode_json(raw)
  local items = decoded and decoded.data or {}

  for _, item in ipairs(items) do
    if title_similarity(title, item.title or "") >= 0.45 then
      local external = item.externalIds or {}
      local result = external.DOI and fetch_bibtex_by_doi(external.DOI) or nil
      if result then
        result.method = "Semantic Scholar title -> " .. result.method
        return result
      end
      if external.ArXiv then
        local fetched = fetch_paper_web_data("https://arxiv.org/abs/" .. external.ArXiv)
        if fetched and trim(fetched.bibtex or "") ~= "" then
          local arxiv_result = result_from_bibtex(fetched.bibtex, "Semantic Scholar title -> arXiv", fetched.source)
          if arxiv_result then
            arxiv_result.title = fetched.title ~= "" and fetched.title or arxiv_result.title
            arxiv_result.abstract = fetched.abstract ~= "" and fetched.abstract or arxiv_result.abstract
            arxiv_result.keywords = #fetched.keywords > 0 and fetched.keywords or arxiv_result.keywords
            return arxiv_result
          end
        end
      end
      return result_from_bibtex(render_semantic_scholar_entry(item), "Semantic Scholar title", item.url)
    end
  end

  return nil
end

local function render_openalex_entry(item)
  local authors = {}
  for _, authorship in ipairs(item.authorships or {}) do
    if authorship.author and authorship.author.display_name then
      authors[#authors + 1] = authorship.author.display_name
    end
  end

  local source = item.primary_location and item.primary_location.source and item.primary_location.source.display_name
    or ""
  return zk_bib.render_entry({
    type = "article",
    key = zk_bib.derive_key({ title = item.display_name, year = item.publication_year }),
    fields = {
      title = item.display_name,
      author = table.concat(authors, " and "),
      year = item.publication_year,
      journal = source,
      doi = item.doi,
      url = item.doi or (item.ids and item.ids.openalex) or "",
    },
  })
end

local function fetch_openalex_by_title(title)
  if #trim(title) < 12 then
    return nil
  end

  local raw = curl_text("https://api.openalex.org/works?per-page=5&search=" .. url_encode(title))
  local decoded = decode_json(raw)
  local items = decoded and decoded.results or {}

  for _, item in ipairs(items) do
    if title_similarity(title, item.display_name or "") >= 0.45 then
      local result = item.doi and fetch_bibtex_by_doi(item.doi) or nil
      if result then
        result.method = "OpenAlex title -> " .. result.method
        return result
      end
      return result_from_bibtex(render_openalex_entry(item), "OpenAlex title", item.doi or item.id)
    end
  end

  return nil
end

local function fetch_inspire_by_title(title)
  if #trim(title) < 12 then
    return nil
  end

  local raw = curl_text(
    "https://inspirehep.net/api/literature?q=" .. url_encode('title:"' .. title .. '"') .. "&size=1&format=bibtex"
  )
  local result = result_from_bibtex(raw, "INSPIRE title", nil)
  if result and title_similarity(title, result.title) >= 0.45 then
    return result
  end
  return nil
end

local function fetch_bibtex_by_title(title)
  local providers = {
    fetch_inspire_by_title,
    fetch_crossref_by_title,
    fetch_semantic_scholar_by_title,
    fetch_openalex_by_title,
  }

  for _, provider in ipairs(providers) do
    local result = provider(title)
    if result then
      return result
    end
  end

  return nil
end

local function fetch_pdf_online_bibtex(path, pdf_meta)
  local probe_text = fetch_pdf_probe_text(path)
  local doi = extract_doi_from_text(probe_text)
  if doi ~= "" then
    local result = fetch_bibtex_by_doi(doi)
    if result then
      return result
    end
  end

  local arxiv_id = extract_arxiv_id_from_text(probe_text)
  if arxiv_id ~= "" then
    local fetched = fetch_paper_web_data("https://arxiv.org/abs/" .. arxiv_id)
    if fetched and trim(fetched.bibtex or "") ~= "" then
      local result = result_from_bibtex(fetched.bibtex, "PDF arXiv id", fetched.source)
      if result then
        result.title = fetched.title ~= "" and fetched.title or result.title
        result.abstract = fetched.abstract ~= "" and fetched.abstract or result.abstract
        result.keywords = #fetched.keywords > 0 and fetched.keywords or result.keywords
        return result
      end
    end
  end

  local title = trim(pdf_meta and pdf_meta.title or "")
  if title == "" or #title < 12 then
    title = infer_pdf_title_from_text(probe_text)
  end
  if title ~= "" then
    return fetch_bibtex_by_title(title)
  end

  return nil
end

local function note_from_defaults(template)
  if template.build_default_note then
    return template.build_default_note()
  end

  return {
    id = nil,
    path = nil,
    title = "",
    metadata = {},
    content = "",
  }
end

local function normalize_note(note)
  note = note or {}
  note.id = note.id
  note.path = note.path
  note.title = trim(note.title or "")
  note.metadata = deep_copy(note.metadata or {})
  note.content = note.content or ""
  return note
end

local function template_items(templates)
  local items = {}
  for _, key in ipairs({ "plain", "web", "paper" }) do
    items[#items + 1] = templates[key]
  end
  return items
end

local function render_form_lines(template)
  local lines = {
    "# ZK Capture",
    "Type: " .. template.key,
    "",
  }

  for _, field in ipairs(template.fields or {}) do
    if field.kind == "text" then
      lines[#lines + 1] = field.label .. ":"
      lines[#lines + 1] = ""
      lines[#lines + 1] = ""
    else
      lines[#lines + 1] = field.label .. ": "
    end
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "# Submit with <C-s>; cancel with q"
  return lines
end

local function next_field_label(template, index)
  for i = index + 1, #(template.fields or {}) do
    return template.fields[i].label .. ":"
  end
  return nil
end

local function parse_form(template, lines)
  local values = {}
  local cursor = 1

  for index, field in ipairs(template.fields or {}) do
    local label = field.label .. ":"
    local found
    for i = cursor, #lines do
      if vim.startswith(lines[i], label) then
        found = i
        break
      end
    end

    if not found then
      values[field.key] = field.kind == "array-string" and {} or ""
      cursor = #lines + 1
    elseif field.kind == "text" then
      local stop_label = next_field_label(template, index)
      local collected = {}
      local start = found + 1
      local finish = #lines
      if stop_label then
        for i = start, #lines do
          if vim.startswith(lines[i], stop_label) then
            finish = i - 1
            break
          end
        end
      else
        for i = start, #lines do
          if vim.startswith(lines[i], "# ") then
            finish = i - 1
            break
          end
        end
      end

      for i = start, finish do
        collected[#collected + 1] = lines[i]
      end
      values[field.key] = trim(table.concat(collected, "\n"))
      cursor = finish + 1
    else
      local raw = trim(lines[found]:sub(#label + 1))
      if field.kind == "array-string" then
        values[field.key] = split_csv(raw)
      else
        values[field.key] = raw
      end
      cursor = found + 1
    end
  end

  return values
end

local function validate_values(template, values)
  for _, field in ipairs(template.fields or {}) do
    if field.required then
      local value = values[field.key]
      if field.kind == "array-string" then
        if type(value) ~= "table" or vim.tbl_isempty(value) then
          return nil, field.label .. " is required"
        end
      elseif trim(value) == "" then
        return nil, field.label .. " is required"
      end
    end
  end

  return true
end

local function empty_form_values(template)
  local values = {}
  for _, field in ipairs(template.fields or {}) do
    values[field.key] = field.kind == "array-string" and {} or ""
  end
  return values
end

local function build_capture_tag_line(existing_line)
  local line = existing_line or ""
  if line == "" then
    return "#tag.capture"
  end
  if line:match("#tag%.capture") then
    return line
  end
  return line .. " #tag.capture"
end

local function build_paper_content(key, body)
  local source_line = "Source: @" .. key
  local trimmed_body = trim(body or "")
  if trimmed_body == "" then
    return source_line
  end
  if trimmed_body:match("^Source:%s*@") then
    return trimmed_body
  end
  return source_line .. "\n\n" .. trimmed_body
end

local function fallback_pdf_title(path)
  local title = basename(path):gsub("%.[^.]+$", ""):gsub("[-_]+", " ")
  return collapse_ws(title)
end

local function warning_list(prefix, err)
  if trim(err or "") == "" then
    return nil
  end
  return { prefix .. err }
end

local function notify_existing_paper(entry, reason)
  local key = entry and entry.key or ""
  if key == "" then
    return
  end
  local suffix = reason and (" (matched by " .. reason .. ")") or ""
  vim.notify("Paper already exists in ref.bib as @" .. key .. suffix, vim.log.levels.INFO)
  zk_bib.open_source_or_entry(key, { wiki_root = wiki_root() })
end

local function fallback_web_bibtex(fetched, raw_source)
  local source = trim(fetched.source or raw_source)
  local title = trim(fetched.title or "")
  if title == "" then
    title = infer_title_from_url(source)
  end
  local key = zk_bib.derive_key({ title = title, url = source })
  return zk_bib.render_entry({
    type = "misc",
    key = key,
    fields = {
      title = title ~= "" and title or source,
      url = source,
    },
  })
end

local function unique_child_path(dir_abs, dir_rel, filename)
  local stem = vim.fn.fnamemodify(filename, ":r")
  local ext = vim.fn.fnamemodify(filename, ":e")
  local candidate = filename
  local index = 2

  while
    vim.fn.filereadable(join_paths(dir_abs, candidate)) == 1
    or vim.fn.isdirectory(join_paths(dir_abs, candidate)) == 1
  do
    candidate = stem .. "-" .. index .. (ext ~= "" and ("." .. ext) or "")
    index = index + 1
  end

  return dir_rel .. "/" .. candidate, join_paths(dir_abs, candidate)
end

local function build_templates()
  return {
    plain = {
      key = "plain",
      label = "Plain",
      description = "Create a normal note without capture metadata",
    },
    web = {
      key = "web",
      label = "Web",
      description = "Capture a webpage with metadata-first notes",
      fields = {
        { key = "title", label = "Title", kind = "string" },
        { key = "url", label = "URL", kind = "string", required = true },
        { key = "abstract", label = "Abstract", kind = "string" },
        { key = "keywords", label = "Keywords", kind = "array-string" },
        { key = "summary", label = "Summary", kind = "text" },
      },
      input_hook = function(ctx, done)
        vim.ui.input({
          prompt = "Web URL: ",
        }, function(input)
          local url = normalize_url(input or "")
          if url == "" then
            done(nil)
            return
          end

          local values = empty_form_values(ctx.template)
          values.url = url
          done(values)
        end)
      end,
      build_default_note = function()
        return {
          id = nil,
          path = nil,
          title = "",
          metadata = {
            abstract = "",
            aliases = {},
            generated = true,
            ["checklist-status"] = "none",
            keywords = {},
            relation = "active",
            ["relation-target"] = {},
            user = {
              public = true,
              ["ai-generated"] = false,
              captured = true,
              source = {},
              ["capture-type"] = "web",
            },
          },
          content = "",
        }
      end,
      apply_form = function(_, values)
        local note = {
          title = trim(values.title),
          metadata = {
            user = {
              source = { values.url },
            },
          },
          content = trim(values.summary),
        }

        if trim(values.abstract) ~= "" then
          note.metadata.abstract = values.abstract
        end
        if type(values.keywords) == "table" and not vim.tbl_isempty(values.keywords) then
          note.metadata.keywords = values.keywords
        end

        return normalize_note(note)
      end,
      hooks = {
        pre_create = function(ctx)
          local source = get_path(ctx.note, { "metadata", "user", "source" })
          local url = type(source) == "table" and source[1] or ""
          url = normalize_url(url)
          if url == "" then
            return nil
          end

          local fetched, err = fetch_url_metadata(url)
          if not fetched then
            local fallback_title = infer_title_from_url(url)
            if fallback_title == "" then
              return {
                warnings = err and { "web pre_create hook: " .. err } or nil,
              }
            end
            return {
              note = {
                title = fallback_title,
              },
              warnings = err and { "web pre_create hook: " .. err } or nil,
            }
          end

          local note = {
            title = fetched.title ~= "" and fetched.title or infer_title_from_url(url),
            metadata = {
              abstract = fetched.abstract,
              keywords = fetched.keywords,
              user = {
                source = { fetched.url },
              },
            },
          }

          return {
            note = note,
          }
        end,
        post_create = nil,
      },
    },
    paper = {
      key = "paper",
      label = "Paper",
      description = "Capture a paper from arXiv/INSPIRE or a local PDF",
      fields = {
        { key = "source_kind", label = "Source Kind", kind = "string", required = true },
        { key = "source", label = "Source", kind = "string", required = true },
        { key = "title", label = "Title", kind = "string" },
        { key = "abstract", label = "Abstract", kind = "string" },
        { key = "keywords", label = "Keywords", kind = "array-string" },
        { key = "summary", label = "Summary", kind = "text" },
      },
      input_hook = function(ctx, done)
        vim.ui.select({ "web", "pdf" }, {
          prompt = "Paper source type",
        }, function(kind)
          if not kind then
            done(nil)
            return
          end

          vim.ui.input({
            prompt = kind == "web" and "Paper URL: " or "PDF path: ",
          }, function(input)
            local source = trim(input or "")
            if source == "" then
              done(nil)
              return
            end

            local values = empty_form_values(ctx.template)
            values.source_kind = kind
            values.source = kind == "web" and normalize_url(source) or source
            done(values)
          end)
        end)
      end,
      build_default_note = function()
        return {
          id = nil,
          path = nil,
          title = "",
          metadata = {
            abstract = "",
            aliases = {},
            generated = true,
            ["checklist-status"] = "none",
            keywords = {},
            relation = "active",
            ["relation-target"] = {},
            user = {
              public = true,
              ["ai-generated"] = false,
              captured = true,
              source = {},
              ["capture-type"] = "paper",
            },
          },
          content = "",
        }
      end,
      apply_form = function(_, values)
        local note = {
          title = trim(values.title),
          metadata = {
            user = {
              source = { values.source },
              ["source-kind"] = values.source_kind,
            },
          },
          content = trim(values.summary),
        }

        if trim(values.abstract) ~= "" then
          note.metadata.abstract = values.abstract
        end
        if type(values.keywords) == "table" and not vim.tbl_isempty(values.keywords) then
          note.metadata.keywords = values.keywords
        end

        return normalize_note(note)
      end,
      hooks = {
        pre_create = function(ctx)
          local source = get_path(ctx.note, { "metadata", "user", "source" })
          local source_kind = get_path(ctx.note, { "metadata", "user", "source-kind" })
          local raw_source = type(source) == "table" and source[1] or ""

          if source_kind == "web" then
            local fetched, err = fetch_paper_web_data(raw_source)
            if not fetched then
              fetched = {
                source = normalize_url(raw_source),
                title = infer_title_from_url(raw_source),
                abstract = "",
                keywords = {},
                bibtex = "",
              }
            end

            local bibtex = trim(fetched.bibtex or "")
            local entry = bibtex ~= "" and zk_bib.parse_entry(bibtex) or nil
            if not entry or trim(entry.key or "") == "" then
              bibtex = fallback_web_bibtex(fetched, raw_source)
              entry = zk_bib.parse_entry(bibtex)
            end

            if not entry or trim(entry.key or "") == "" then
              return {
                abort = true,
                errors = { "paper pre_create hook: failed to derive BibTeX key" },
              }
            end

            local duplicate, reason = zk_bib.find_duplicate({
              key = entry.key,
              fields = entry.fields,
              url = fetched.source or raw_source,
              bibtex = bibtex,
            }, { wiki_root = ctx.wiki_root })
            if duplicate then
              notify_existing_paper(duplicate, reason)
              return { abort = true }
            end

            local ok, append_err = zk_bib.append_entry(bibtex, { wiki_root = ctx.wiki_root })
            if not ok then
              return {
                abort = true,
                errors = { "paper pre_create hook: failed to append ref.bib: " .. append_err },
              }
            end

            local title = trim(fetched.title or "")
            if title == "" then
              title = zk_bib.clean_title(zk_bib.field(entry, "title"))
            end

            return {
              note = {
                title = title,
                content = build_paper_content(entry.key, ctx.note.content),
                metadata = {
                  abstract = fetched.abstract or "",
                  keywords = fetched.keywords or {},
                  user = {
                    source = { fetched.source or raw_source },
                  },
                },
              },
              override_paths = { { "content" } },
              warnings = warning_list("paper pre_create hook: ", err),
            }
          end

          if source_kind == "pdf" then
            local source_abs = vim.fn.expand(raw_source)
            local fetched = fetch_pdf_metadata(source_abs)
            local online = fetch_pdf_online_bibtex(source_abs, fetched)
            local bibtex = online and trim(online.bibtex or "") or ""
            local entry = bibtex ~= "" and zk_bib.parse_entry(bibtex) or nil

            local title = trim(ctx.note.title)
            if title == "" and online then
              title = trim(online.title or "")
            end
            if title == "" then
              title = trim(fetched.title or "")
            end
            if title == "" then
              title = fallback_pdf_title(raw_source)
            end

            local key = entry and trim(entry.key or "") or ""
            if key == "" then
              key = zk_bib.derive_key({ title = title, file = raw_source })
            end

            local duplicate, reason = zk_bib.find_duplicate({
              key = key,
              fields = entry and entry.fields or { file = raw_source },
              file = raw_source,
              bibtex = bibtex,
            }, { wiki_root = ctx.wiki_root })
            if duplicate then
              notify_existing_paper(duplicate, reason)
              return { abort = true }
            end

            local abstract = online and trim(online.abstract or "") or ""
            if abstract == "" then
              abstract = fetched.abstract or ""
            end

            local keywords = online and online.keywords or {}
            if not keywords or vim.tbl_isempty(keywords) then
              keywords = fetched.keywords or {}
            end

            local info
            if online and trim(online.method or "") ~= "" then
              info = { "paper pdf pre_create hook: fetched BibTeX via " .. online.method }
            end

            return {
              note = {
                title = title,
                content = build_paper_content(key, ctx.note.content),
                paper_bibtex = bibtex,
                metadata = {
                  abstract = abstract,
                  keywords = keywords,
                },
              },
              override_paths = { { "content" }, { "paper_bibtex" } },
              info = info,
            }
          end

          return nil
        end,
        post_create = function(ctx)
          local source = get_path(ctx.note, { "metadata", "user", "source" })
          local source_kind = get_path(ctx.note, { "metadata", "user", "source-kind" })
          local raw_source = type(source) == "table" and source[1] or ""

          if source_kind ~= "pdf" or trim(raw_source) == "" then
            return nil
          end

          local note_id = ctx.note.id
          if trim(note_id or "") == "" then
            return {
              warnings = { "paper post_create hook: missing note id" },
            }
          end

          local source_abs = vim.fn.expand(raw_source)
          local filename = zk_bib.slugify_filename(basename(source_abs))
          local asset_dir_rel = "assets/" .. note_id .. "-pdf"
          local asset_dir_abs = join_paths(ctx.wiki_root, asset_dir_rel)

          local mkdir_ok = vim.fn.mkdir(asset_dir_abs, "p")
          if mkdir_ok == 0 and vim.fn.isdirectory(asset_dir_abs) == 0 then
            return {
              warnings = { "paper post_create hook: failed to create asset dir" },
            }
          end

          local target_rel, target_abs = unique_child_path(asset_dir_abs, asset_dir_rel, filename)
          local move_result = vim.system({ "mv", source_abs, target_abs }, { text = true }):wait()
          if move_result.code ~= 0 then
            return {
              warnings = {
                "paper post_create hook: failed to move pdf: " .. collapse_ws(move_result.stderr or ""),
              },
            }
          end

          local fetched = fetch_pdf_metadata(target_abs)
          local warnings = {}
          local bib_key = zk_bib.source_key_from_content(ctx.note.content)
          if trim(bib_key or "") == "" then
            warnings[#warnings + 1] = "paper post_create hook: missing Source bibkey"
          else
            local title = trim(ctx.note.title)
            if title == "" then
              title = trim(fetched.title or "")
            end
            if title == "" then
              title = fallback_pdf_title(target_rel)
            end

            local existing = zk_bib.find_entry_by_key(bib_key, { wiki_root = ctx.wiki_root })
            local ok, bib_err
            if existing then
              ok, bib_err = zk_bib.set_entry_field(bib_key, "file", target_rel, { wiki_root = ctx.wiki_root })
            else
              local pending_bibtex = trim(ctx.note.paper_bibtex or "")
              if pending_bibtex ~= "" then
                ok, bib_err = zk_bib.append_entry(pending_bibtex, { wiki_root = ctx.wiki_root })
                if ok then
                  ok, bib_err = zk_bib.set_entry_field(bib_key, "file", target_rel, { wiki_root = ctx.wiki_root })
                end
              else
                ok, bib_err = zk_bib.append_entry(
                  zk_bib.render_entry({
                    type = "misc",
                    key = bib_key,
                    fields = {
                      title = title,
                      file = target_rel,
                    },
                  }),
                  { wiki_root = ctx.wiki_root }
                )
              end
            end
            if not ok then
              warnings[#warnings + 1] = "paper post_create hook: failed to update ref.bib: " .. bib_err
            end
          end

          local note_update = {
            metadata = {
              user = {
                source = { target_rel },
              },
            },
          }
          if trim(ctx.note.title or "") == "" and trim(fetched.title or "") ~= "" then
            note_update.title = fetched.title
          end
          if trim(fetched.abstract or "") ~= "" then
            note_update.metadata.abstract = fetched.abstract
          end
          if type(fetched.keywords) == "table" and not vim.tbl_isempty(fetched.keywords) then
            note_update.metadata.keywords = fetched.keywords
          end

          return {
            note = note_update,
            warnings = #warnings > 0 and warnings or nil,
          }
        end,
      },
    },
  }
end

local function run_hook(template, hook_name, note, user_note)
  local hook = template.hooks and template.hooks[hook_name]
  if type(hook) ~= "function" then
    return nil
  end

  local result = hook({
    template_key = template.key,
    note = deep_copy(note),
    user_note = deep_copy(user_note),
    wiki_root = wiki_root(),
    mode = hook_name,
  })

  if type(result) ~= "table" then
    return nil
  end

  if type(result.errors) == "table" and not vim.tbl_isempty(result.errors) then
    vim.notify(result.errors[1], vim.log.levels.ERROR)
    return nil, { abort = true }
  end

  if type(result.warnings) == "table" then
    for _, warning in ipairs(result.warnings) do
      vim.notify(warning, vim.log.levels.WARN)
    end
  end

  if type(result.info) == "table" then
    for _, message in ipairs(result.info) do
      vim.notify(message, vim.log.levels.INFO)
    end
  end

  if result.abort then
    return nil, result
  end

  return deep_copy(result.note or {}), result
end

local function apply_override_paths(target, source, paths)
  if type(paths) ~= "table" then
    return
  end
  for _, path in ipairs(paths) do
    if type(path) == "string" then
      path = { path }
    end
    if type(path) == "table" and #path > 0 then
      local value = get_path(source, path)
      if value ~= nil then
        set_path(target, path, deep_copy(value))
      end
    end
  end
end

local function resolve_note(template, values)
  local default_note = normalize_note(note_from_defaults(template))
  local user_note = normalize_note(template.apply_form and template.apply_form(default_note, values) or {})
  local note = deep_copy(default_note)

  merge_missing(note, user_note, {})
  local pre_create_note, pre_create_result = run_hook(template, "pre_create", note, user_note)
  if pre_create_result and pre_create_result.abort then
    return nil, user_note
  end
  if pre_create_note then
    merge_missing(note, pre_create_note, user_note)
    apply_override_paths(note, pre_create_note, pre_create_result and pre_create_result.override_paths)
  end

  return normalize_note(note), user_note
end

local function create_note(note)
  local cmd = { "zk-lsp", "new", "--wiki-root", wiki_root() }
  local input

  if trim(note.title) ~= "" then
    cmd[#cmd + 1] = "--json"
    input = vim.json.encode({ title = note.title })
  end

  for _, meta in ipairs(flatten_metadata(note.metadata)) do
    cmd[#cmd + 1] = "--meta"
    cmd[#cmd + 1] = meta.key .. "=" .. toml_literal(meta.value)
  end

  local note_path = trim(vim.fn.system(cmd, input))
  if vim.v.shell_error ~= 0 or note_path == "" then
    local message = note_path ~= "" and note_path or "zk-lsp new failed"
    vim.notify(message, vim.log.levels.ERROR)
    return nil
  end

  return note_path
end

local function enrich_created_note(note, note_path)
  note = normalize_note(deep_copy(note))
  note.path = note_path
  note.id = note_path:match("note/(%d+)%.typ$")
  return note
end

local function update_title_line(bufnr, title)
  if trim(title) == "" then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local note_id = line:match("^=%s*.-%s*<(%d+)>%s*$") or line:match("^=%s*<(%d+)>%s*$")
    if note_id then
      lines[i] = "= " .. title .. " <" .. note_id .. ">"
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      return
    end
  end
end

local function update_metadata_block(bufnr, metadata)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local start_idx
  local end_idx

  for i, line in ipairs(lines) do
    if line:match("^#let zk%-metadata = toml%(bytes%(") then
      start_idx = i
    elseif start_idx and line:match("^%s*%)%)[%s]*$") then
      end_idx = i
      break
    end
  end

  if not start_idx or not end_idx then
    return
  end

  vim.api.nvim_buf_set_lines(bufnr, start_idx - 1, end_idx, false, render_metadata_lines(metadata))
end

local function ensure_capture_tag(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local title_index
  for i, line in ipairs(lines) do
    if not title_index and line:match("^=%s+") then
      title_index = i
    end
    if line:match("^#tag%.") then
      local updated = build_capture_tag_line(line)
      if updated ~= line then
        lines[i] = updated
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      end
      return
    end
  end

  if title_index then
    vim.api.nvim_buf_set_lines(bufnr, title_index, title_index, false, { "#tag.capture" })
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end

  for i = 1, #lines - 2 do
    if lines[i]:match("^#tag%.") and lines[i + 1] == "" and lines[i + 2]:match("^#status_tag%(") then
      vim.api.nvim_buf_set_lines(bufnr, i, i + 1, false, {})
      break
    end
  end
end

local function update_content(bufnr, content)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local status_index

  for i, line in ipairs(lines) do
    if line:match("^#status_tag%(") then
      status_index = i
      break
    end
  end

  if not status_index then
    return
  end

  local content_lines = {}
  local body = trim(content)
  if body ~= "" then
    for part in (body .. "\n"):gmatch("(.-)\n") do
      content_lines[#content_lines + 1] = part
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, status_index, -1, false, content_lines)
end

local function focus_body(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match("^#status_tag%(") then
      local target = math.min(i + 2, #lines)
      if target < 1 then
        target = 1
      end
      vim.api.nvim_win_set_cursor(0, { target, 0 })
      return
    end
  end
end

local function finalize_note(note_path, note, on_complete)
  vim.cmd("cd " .. vim.fn.fnameescape(wiki_root()))
  vim.cmd("edit " .. vim.fn.fnameescape(note_path))

  local bufnr = vim.api.nvim_get_current_buf()
  update_metadata_block(bufnr, note.metadata)
  update_title_line(bufnr, note.title)
  ensure_capture_tag(bufnr)
  update_content(bufnr, note.content)
  vim.cmd("silent write")

  vim.schedule(function()
    focus_body(bufnr)
  end)

  if on_complete then
    on_complete(note_path, note)
  end
end

local function run_post_create_hook(template, note, user_note)
  local post_note = run_hook(template, "post_create", note, user_note)
  if not post_note then
    return note
  end

  local merged = deep_copy(note)
  local guard = deep_copy(user_note)
  clear_path(guard, { "metadata", "user", "source" })
  merge_override(merged, post_note, guard)
  merged.id = note.id
  merged.path = note.path
  return normalize_note(merged)
end

local submit_values

local function open_form(template, on_complete)
  local lines = render_form_lines(template)
  vim.cmd("botright 14split")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_name(buf, "zk-capture://" .. template.key)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local function close_form()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function submit_form()
    local values = parse_form(template, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    local ok, err = validate_values(template, values)
    if not ok then
      vim.notify(err, vim.log.levels.WARN)
      return
    end

    close_form()
    submit_values(template, values, on_complete)
  end

  vim.keymap.set({ "n", "i" }, "<C-s>", submit_form, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "q", close_form, { buffer = buf, nowait = true, silent = true })

  vim.schedule(function()
    vim.api.nvim_win_set_cursor(win, { 4, #"Title: " })
    vim.cmd("startinsert!")
  end)
end

submit_values = function(template, values, on_complete)
  local ok, err = validate_values(template, values)
  if not ok then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local note, user_note = resolve_note(template, values)
  if not note then
    return
  end

  local note_path = create_note(note)
  if not note_path then
    return
  end

  local created_note = enrich_created_note(note, note_path)
  local final_note = run_post_create_hook(template, created_note, user_note)
  finalize_note(note_path, final_note, on_complete)
end

local function start_template_input(template, on_complete)
  if type(template.input_hook) == "function" then
    template.input_hook({
      template_key = template.key,
      template = template,
      wiki_root = wiki_root(),
    }, function(values)
      if not values then
        return
      end
      submit_values(template, values, on_complete)
    end)
    return
  end

  open_form(template, on_complete)
end

function M.paper_note_from_ref(key, on_complete)
  local function create_for_key(ref_key)
    ref_key = trim((ref_key or ""):gsub("^@", ""))
    if ref_key == "" then
      return
    end

    local entry = zk_bib.find_entry_by_key(ref_key, { wiki_root = wiki_root() })
    if not entry then
      vim.notify("No ref.bib entry found for @" .. ref_key, vim.log.levels.WARN)
      return
    end

    local matches = zk_bib.find_source_notes(ref_key, { wiki_root = wiki_root() })
    if #matches > 0 then
      vim.notify("Paper note already exists for @" .. ref_key, vim.log.levels.INFO)
      zk_bib.open_source_or_entry(ref_key, { wiki_root = wiki_root() })
      return
    end

    local template = build_templates().paper
    local note = normalize_note(note_from_defaults(template))
    local source = zk_bib.entry_primary_source(entry, { wiki_root = wiki_root() })
    local keywords = split_words(zk_bib.field(entry, "keywords"))

    note.title = zk_bib.clean_title(zk_bib.field(entry, "title"))
    if note.title == "" then
      note.title = ref_key
    end
    note.content = build_paper_content(ref_key, "")
    note.metadata.abstract = zk_bib.field(entry, "abstract")
    note.metadata.keywords = keywords
    if trim(source) ~= "" then
      note.metadata.user.source = { source }
    end

    local note_path = create_note(note)
    if not note_path then
      return
    end

    local created_note = enrich_created_note(note, note_path)
    finalize_note(note_path, created_note, on_complete)
  end

  key = trim((key or ""):gsub("^@", ""))
  if key ~= "" then
    create_for_key(key)
    return
  end

  local default_key = trim(vim.fn.expand("<cword>"):gsub("^@", ""))
  vim.ui.input({
    prompt = "BibTeX key: @",
    default = default_key,
  }, create_for_key)
end

function M.start(on_complete, fallback)
  local templates = build_templates()
  vim.ui.select(template_items(templates), {
    prompt = "Select capture type",
    format_item = function(item)
      return string.format("%s - %s", item.label, item.description)
    end,
  }, function(choice)
    if not choice then
      return
    end

    if choice.key == "plain" then
      if fallback then
        fallback()
      end
      return
    end

    start_template_input(choice, on_complete)
  end)
end

return M
