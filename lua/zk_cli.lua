local M = {}

local uv = vim.uv

local note_info_cache = {}
local persistent_cache = nil
local cache_dirty = false
local pending_refresh = {}
local refresh_queue = {}
local active_refreshes = 0

local MAX_NOTE_INFO_ATTEMPTS = 3
local MAX_CONCURRENT_REFRESHES = 4

local function home_dir()
  return uv.os_homedir() or os.getenv("HOME") or "~"
end

local function wiki_root()
  return vim.fs.normalize(home_dir() .. "/wiki")
end

local function cache_path()
  return vim.fn.stdpath("cache") .. "/zk_note_info_cache.json"
end

local function note_paths()
  return vim.fn.globpath(wiki_root() .. "/note", "*.typ", false, true)
end

local function note_state(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return nil
  end

  return {
    mtime = stat.mtime and stat.mtime.sec or 0,
    size = stat.size or 0,
  }
end

local function state_equals(a, b)
  return a and b and a.mtime == b.mtime and a.size == b.size
end

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
    if line:match("^=%s+.+%s+<%d+>%s*$") then
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
  local heading_match = heading:match("^=%s*(.-)%s*<%d+>%s*$")
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

local function normalize_note_info(note, opts)
  opts = opts or {}
  if type(note) ~= "table" or type(note.id) ~= "string" or type(note.path) ~= "string" then
    return nil
  end

  local base = local_note_info(note.id, note.path, { include_references = opts.include_references })
  if not base then
    return nil
  end

  local metadata = note.metadata or {}
  local tags = vim.deepcopy(base.tags)
  local status = metadata["checklist-status"]

  if type(status) == "string" and status ~= "" and status ~= "none" then
    local found = false
    for _, tag in ipairs(tags) do
      if tag == status then
        found = true
        break
      end
    end
    if not found then
      tags[#tags + 1] = status
    end
  end

  return {
    id = note.id,
    path = note.path,
    title = note.title or base.title,
    metadata = metadata,
    tags = tags,
    aliases = metadata.aliases or {},
    abstract = metadata.abstract or "",
    keywords = metadata.keywords or {},
    title_line = base.title_line,
    references = base.references,
    _source = "zk-lsp",
  }
end

local function decode_json(stdout, context)
  local ok, decoded = pcall(vim.json.decode, stdout)
  if ok then
    return decoded
  end

  vim.notify("Failed to decode JSON from " .. context, vim.log.levels.WARN)
  return nil
end

local function load_persistent_cache()
  if persistent_cache ~= nil then
    return persistent_cache
  end

  persistent_cache = {}
  if vim.fn.filereadable(cache_path()) == 0 then
    return persistent_cache
  end

  local lines = vim.fn.readfile(cache_path())
  local raw = table.concat(lines, "\n")
  if raw == "" then
    return persistent_cache
  end

  local ok, decoded = pcall(vim.json.decode, raw)
  if ok and type(decoded) == "table" then
    persistent_cache = decoded
  end

  return persistent_cache
end

local function save_persistent_cache()
  if not cache_dirty or not persistent_cache then
    return
  end

  local ok, encoded = pcall(vim.json.encode, persistent_cache)
  if not ok then
    return
  end

  vim.fn.mkdir(vim.fn.fnamemodify(cache_path(), ":h"), "p")
  vim.fn.writefile(vim.split(encoded, "\n", { plain = true }), cache_path())
  cache_dirty = false
end

local function schedule_cache_save()
  vim.defer_fn(save_persistent_cache, 200)
end

local function cache_note(note)
  local state = note_state(note.path)
  if not state then
    return
  end

  note_info_cache[note.id] = note
  local cache = load_persistent_cache()
  cache[note.id] = {
    state = state,
    note = note,
  }
  cache_dirty = true
  schedule_cache_save()
end

local function get_cached_note(id, path, opts)
  opts = opts or {}

  local state = note_state(path)
  if not state then
    return nil
  end

  local mem = note_info_cache[id]
  if mem and state_equals(state, load_persistent_cache()[id] and load_persistent_cache()[id].state) then
    if opts.include_references and (not mem.references or next(mem.references) == nil) then
      mem.references = local_note_info(id, path, { include_references = true }).references
    end
    return mem
  end

  local cache = load_persistent_cache()[id]
  if cache and state_equals(state, cache.state) and type(cache.note) == "table" then
    local note = vim.deepcopy(cache.note)
    if opts.include_references and (not note.references or next(note.references) == nil) then
      note.references = local_note_info(id, path, { include_references = true }).references
    end
    note_info_cache[id] = note
    return note
  end

  return nil
end

local function run_note_info_async(id, callback)
  vim.system({ "zk-lsp", "note-info", id }, {
    text = true,
    cwd = wiki_root(),
  }, callback)
end

local function finish_refresh(id)
  pending_refresh[id] = nil
  active_refreshes = math.max(0, active_refreshes - 1)
end

local function pump_refresh_queue()
  while active_refreshes < MAX_CONCURRENT_REFRESHES and #refresh_queue > 0 do
    local item = table.remove(refresh_queue, 1)
    local id = item.id

    if not pending_refresh[id] then
      pending_refresh[id] = true
      active_refreshes = active_refreshes + 1

      local attempts = 0
      local function try_once()
        attempts = attempts + 1
        run_note_info_async(id, vim.schedule_wrap(function(result)
          if result.code == 0 and result.stdout and result.stdout ~= "" then
            local decoded = decode_json(result.stdout, "zk-lsp note-info " .. id)
            local note = normalize_note_info(decoded, {
              include_references = item.include_references,
            })
            if note then
              cache_note(note)
              finish_refresh(id)
              if item.on_done then
                item.on_done(note)
              end
              pump_refresh_queue()
              return
            end
          end

          if attempts < MAX_NOTE_INFO_ATTEMPTS then
            try_once()
            return
          end

          finish_refresh(id)
          pump_refresh_queue()
        end))
      end

      try_once()
    end
  end
end

local function ensure_refresh(id, opts)
  opts = opts or {}
  if pending_refresh[id] then
    return
  end

  refresh_queue[#refresh_queue + 1] = {
    id = id,
    include_references = opts.include_references,
    on_done = opts.on_done,
  }
  pump_refresh_queue()
end

function M.note_info(id, opts)
  opts = opts or {}
  local path = wiki_root() .. "/note/" .. id .. ".typ"
  if vim.in_fast_event() then
    local cached = note_info_cache[id]
    if cached then
      return cached
    end

    local fallback = local_note_info(id, path, { include_references = opts.include_references })
    if fallback then
      note_info_cache[id] = fallback
    end
    return fallback
  end

  local cached = not opts.refresh and get_cached_note(id, path, {
    include_references = opts.include_references,
  })
  if cached then
    return cached
  end

  if opts.async then
    local fallback = local_note_info(id, path, { include_references = opts.include_references })
    if fallback then
      note_info_cache[id] = fallback
      ensure_refresh(id, {
        include_references = opts.include_references,
        on_done = opts.on_done,
      })
    end
    return fallback
  end

  local fallback = local_note_info(id, path, { include_references = opts.include_references })
  if fallback then
    note_info_cache[id] = fallback
  end

  local last_error
  for _ = 1, MAX_NOTE_INFO_ATTEMPTS do
    local result = vim.system({ "zk-lsp", "note-info", id }, {
      text = true,
      cwd = wiki_root(),
    }):wait()

    if result.code == 0 and result.stdout and result.stdout ~= "" then
      local decoded = decode_json(result.stdout, "zk-lsp note-info " .. id)
      local note = normalize_note_info(decoded, {
        include_references = opts.include_references,
      })
      if note then
        cache_note(note)
        return note
      end
      last_error = "json decode failed"
    else
      local stderr = (result.stderr or ""):gsub("%s+$", "")
      last_error = stderr ~= "" and stderr or ("exit code " .. tostring(result.code))
    end
  end

  if fallback then
    return fallback
  end

  if not opts.silent then
    vim.notify("zk-lsp note-info failed for " .. id .. (last_error and (": " .. last_error) or ""), vim.log.levels.WARN)
  end

  return nil
end

function M.note_info_by_file(path, opts)
  opts = opts or {}
  local resolved = resolve_file_path(path, opts.cwd)
  if not resolved then
    return nil
  end

  local id = resolved:match("/note/(%d+)%.typ$")
  if not id then
    return nil
  end

  return M.note_info(id, opts)
end

function M.list_notes(opts)
  opts = opts or {}

  local notes = {}
  for _, path in ipairs(note_paths()) do
    local id = vim.fn.fnamemodify(path, ":t:r")
    if id:match("^%d+$") then
      local note = get_cached_note(id, path, {
        include_references = opts.include_references,
      })

      if not note then
        note = local_note_info(id, path, {
          include_references = opts.include_references,
        })
        if note then
          note_info_cache[id] = note
          ensure_refresh(id, {
            include_references = opts.include_references,
          })
        end
      end

      if note then
        notes[#notes + 1] = note
      end
    end
  end

  table.sort(notes, function(a, b)
    return a.id > b.id
  end)

  return notes
end

function M.refresh_all_async(opts)
  opts = opts or {}
  for _, path in ipairs(note_paths()) do
    local id = vim.fn.fnamemodify(path, ":t:r")
    if id:match("^%d+$") then
      ensure_refresh(id, {
        include_references = opts.include_references,
      })
    end
  end
end

function M.write_json_file(path, value)
  local ok, encoded = pcall(vim.json.encode, value)
  if not ok then
    return false, "json encode failed"
  end

  local lines = vim.split(encoded, "\n", { plain = true })
  local write_ok = pcall(vim.fn.writefile, lines, path)
  if not write_ok then
    return false, "writefile failed"
  end

  return true
end

return M
