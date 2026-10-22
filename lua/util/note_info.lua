local M = {}
local uv = vim.uv

local function resolve_file_path(path, cwd)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  if path:match("^%w+://") then
    return nil
  end

  local base = path
  if not path:match("^/") then
    local root = type(cwd) == "string" and cwd ~= "" and cwd or uv.cwd() or "."
    base = root .. "/" .. path
  end

  return vim.fs.normalize(base)
end

local function read_lines(path)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then
    return nil
  end

  local stat = uv.fs_fstat(fd)
  if not stat or not stat.size then
    uv.fs_close(fd)
    return nil
  end

  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  if type(data) ~= "string" then
    return nil
  end

  data = data:gsub("\r\n", "\n")
  return vim.split(data, "\n", { plain = true })
end

local function title_line_from_lines(lines)
  for i, line in ipairs(lines) do
    if line:match("^=%s+.+%s+<[%dT]+>%s*$") then
      return i
    end
  end
  return 1
end

local function parse_inline_array(line)
  local values = {}
  for value in line:gmatch('"([^"]*)"') do
    if value ~= "" then
      values[#values + 1] = value
    end
  end
  return values
end

local function local_note_info(id, path, opts)
  opts = opts or {}
  if not uv.fs_stat(path) then
    return nil
  end

  local lines = read_lines(path)
  if not lines then
    return nil
  end
  local title_line = title_line_from_lines(lines)
  local title = "Untitled"
  local heading = lines[title_line] or ""
  local heading_match = heading:match("^=%s*(.-)%s*<[%dT]+>%s*$")
  if heading_match and heading_match ~= "" then
    title = heading_match
  end

  local tags = {}
  local tag_line = lines[title_line + 1] or ""
  for tag in tag_line:gmatch("#tag%.([%w_]+)") do
    tags[#tags + 1] = tag
  end

  local metadata = {
    aliases = {},
    abstract = "",
    keywords = {},
  }

  for i = 1, math.min(#lines, 40) do
    local line = lines[i]
    if line:match("^%s*aliases%s*=") then
      metadata.aliases = parse_inline_array(line)
    elseif line:match("^%s*keywords%s*=") then
      metadata.keywords = parse_inline_array(line)
    else
      local key, value = line:match('^%s*([%w%-]+)%s*=%s*"(.*)"%s*$')
      if key and value then
        metadata[key] = value
      end
    end
  end

  local status = metadata["checklist-status"]
  if type(status) == "string" and status ~= "" and status ~= "none" then
    tags[#tags + 1] = status
  end

  local references = {}
  if opts.include_references then
    for _, line in ipairs(lines) do
      for ref_id in line:gmatch("@(%d+)") do
        references[ref_id] = true
      end
    end
  end

  return {
    id = id,
    path = path,
    title = title,
    metadata = metadata,
    tags = tags,
    aliases = metadata.aliases or {},
    abstract = metadata.abstract or "",
    keywords = metadata.keywords or {},
    title_line = title_line,
    references = references,
    _source = "local",
  }
end

-- Read note display metadata directly; no external CLI or background refresh.
function M.note_info_by_file(path, opts)
  opts = opts or {}
  local resolved = resolve_file_path(path, opts.cwd)
  if not resolved then return nil end
  local id = resolved:match("/note/(%d%d%d%d%d%d%d%dT%d%d%d%d%d%d)%.typ$")
    or resolved:match("/note/(%d+)%.typ$")
  if not id then return nil end
  return local_note_info(id, resolved, opts)
end

return M
