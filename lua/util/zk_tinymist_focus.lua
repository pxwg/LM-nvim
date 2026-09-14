local M = {}

local uv = vim.uv or vim.loop
local wiki_root = vim.fs.normalize(vim.fn.expand("~/wiki"))
local note_root = vim.fs.joinpath(wiki_root, "note")
local focus_main = vim.fs.joinpath(wiki_root, "focus.typ")
local manifest_path = vim.fs.joinpath(wiki_root, ".zk-lsp", "focus-v1.json")
local projects_manifest_path = vim.fs.joinpath(wiki_root, ".zk-lsp", "projects-v1.json")

local state = {
  active_buf = nil,
  active_id = nil,
  generation = 0,
  last_error = nil,
  last_notified_error = nil,
  last_member_ids = {},
  last_payload = nil,
  last_project = "",
  last_projects_payload = nil,
  last_reference_ids = {},
  projects_dirty = true,
  loading_notes = false,
  notes = nil,
  notes_waiters = {},
  setup = false,
  timer = nil,
}

local function normalize(path)
  if not path or path == "" then
    return ""
  end
  return vim.fs.normalize(path)
end

local function note_id_from_path(path)
  path = normalize(path)
  local prefix = note_root .. "/"
  if path:sub(1, #prefix) ~= prefix then
    return nil
  end

  local filename = path:sub(#prefix + 1)
  return filename:match("^(%d%d%d%d%d%d%d%d%d%d)%.typ$")
end

local function note_id_from_buffer(bufnr)
  bufnr = bufnr or 0
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  return note_id_from_path(vim.api.nvim_buf_get_name(bufnr))
end

local function visible_typst_source(line, comment_state)
  local chunks = {}
  local cursor = 1

  while cursor <= #line do
    if comment_state.block then
      local close = line:find("*/", cursor, true)
      if not close then
        return table.concat(chunks)
      end
      comment_state.block = false
      cursor = close + 2
    else
      local block = line:find("/*", cursor, true)
      local line_comment = line:find("//", cursor, true)
      if line_comment and (not block or line_comment < block) then
        chunks[#chunks + 1] = line:sub(cursor, line_comment - 1)
        break
      elseif block then
        chunks[#chunks + 1] = line:sub(cursor, block - 1)
        comment_state.block = true
        cursor = block + 2
      else
        chunks[#chunks + 1] = line:sub(cursor)
        break
      end
    end
  end

  return table.concat(chunks)
end

local function reference_ids_from_lines(lines)
  local comment_state = { block = false, fence = false }
  local found = {}

  for _, line in ipairs(lines) do
    if line:match("^%s*```") then
      comment_state.fence = not comment_state.fence
    elseif not comment_state.fence then
      local source = visible_typst_source(line, comment_state)
      local cursor = 1
      while cursor <= #source do
        local start_pos, end_pos, id = source:find("@(%d%d%d%d%d%d%d%d%d%d)", cursor)
        if not start_pos then
          break
        end

        local following = source:sub(end_pos + 1, end_pos + 1)
        if following == "" or not following:match("%d") then
          found[id] = true
        end
        cursor = end_pos + 1
      end
    end
  end

  local ids = vim.tbl_keys(found)
  table.sort(ids)
  return ids
end

local function reference_ids(bufnr)
  return reference_ids_from_lines(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
end

local function note_project(note)
  local metadata = type(note) == "table" and note.metadata or nil
  local user = type(metadata) == "table" and metadata.user or nil
  local project = type(user) == "table" and user.project or nil
  return type(project) == "string" and project or ""
end

local function project_members(current)
  local project = note_project(current)
  if project == "" then
    return { current }, project
  end

  local members = {}
  for _, note in pairs(state.notes or {}) do
    if note_project(note) == project then
      members[#members + 1] = note
    end
  end
  table.sort(members, function(a, b)
    return a.id < b.id
  end)
  return members, project
end

local function note_path(note)
  local path = normalize(note.path)
  if path == "" then
    return vim.fs.joinpath(note_root, note.id .. ".typ")
  end
  if path:sub(1, 1) ~= "/" then
    return vim.fs.joinpath(wiki_root, path)
  end
  return path
end

local function note_lines(note, active_bufnr, active_id)
  if note.id == active_id then
    return vim.api.nvim_buf_get_lines(active_bufnr, 0, -1, false)
  end

  local path = note_path(note)
  local bufnr = vim.fn.bufnr(path, false)
  if bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr) then
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, string.format("failed to read project member %s: %s", note.id, lines)
  end
  return lines
end

local function note_reference_ids(note, active_bufnr, active_id)
  local lines, err = note_lines(note, active_bufnr, active_id)
  if not lines then
    return nil, err
  end
  return reference_ids_from_lines(lines)
end

local function finish_notes_load(notes, err)
  state.loading_notes = false
  if notes then
    state.notes = notes
    state.projects_dirty = true
    state.last_error = nil
  else
    state.last_error = err
  end

  local waiters = state.notes_waiters
  state.notes_waiters = {}
  for _, callback in ipairs(waiters) do
    callback(notes ~= nil, err)
  end
end

local function load_notes(force, callback)
  if state.notes and not force then
    callback(true)
    return
  end

  state.notes_waiters[#state.notes_waiters + 1] = callback
  if state.loading_notes then
    return
  end

  state.loading_notes = true
  local completed = false
  local process

  local function complete(notes, err)
    if completed then
      return
    end
    completed = true
    vim.schedule(function()
      finish_notes_load(notes, err)
    end)
  end

  process = vim.system({
    "zk-lsp",
    "--wiki-root",
    wiki_root,
    "notes",
    "--json",
    "--compact",
  }, { text = true }, function(result)
    if result.code ~= 0 then
      local message = vim.trim(result.stderr or "")
      complete(nil, message ~= "" and message or ("zk-lsp exited with code " .. result.code))
      return
    end

    local ok, decoded = pcall(vim.json.decode, result.stdout or "")
    if not ok or type(decoded) ~= "table" then
      complete(nil, ok and "zk-lsp returned a non-list notes payload" or decoded)
      return
    end

    local notes = {}
    for _, note in ipairs(decoded) do
      if type(note) == "table" and type(note.id) == "string" then
        notes[note.id] = note
      end
    end
    complete(notes)
  end)

  vim.defer_fn(function()
    if completed then
      return
    end
    if process then
      pcall(process.kill, process, 15)
    end
    complete(nil, "zk-lsp notes timed out after 5 seconds")
  end, 5000)
end

local function atomic_write(path, content)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local temporary = string.format("%s.tmp.%d", path, uv.hrtime())
  local fd, open_err = uv.fs_open(temporary, "w", 420)
  if not fd then
    return false, open_err
  end

  local written, write_err = uv.fs_write(fd, content, 0)
  if not written then
    uv.fs_close(fd)
    uv.fs_unlink(temporary)
    return false, write_err
  end

  uv.fs_fsync(fd)
  uv.fs_close(fd)
  local renamed, rename_err = uv.fs_rename(temporary, path)
  if not renamed then
    uv.fs_unlink(temporary)
    return false, rename_err
  end
  return true
end

local function build_projects_manifest()
  local notes = state.notes or {}
  local ids = vim.tbl_keys(notes)
  table.sort(ids)

  local manifest_notes = {}
  local grouped = {}
  local references_by_id = {}
  for _, id in ipairs(ids) do
    local note = notes[id]
    local project = note_project(note)
    local note_refs, read_err = note_reference_ids(note, nil, nil)
    if not note_refs then
      return nil, read_err
    end
    references_by_id[id] = note_refs

    local references = {}
    for _, target_id in ipairs(note_refs) do
      local target = notes[target_id]
      if target and target_id ~= id then
        references[#references + 1] = {
          id = target_id,
          title = target.title or target_id,
        }
      end
    end
    manifest_notes[#manifest_notes + 1] = {
      id = id,
      path = "note/" .. id .. ".typ",
      project = project,
      references = references,
    }
    if project ~= "" then
      grouped[project] = grouped[project] or {}
      grouped[project][#grouped[project] + 1] = note
    end
  end

  local project_keys = vim.tbl_keys(grouped)
  table.sort(project_keys)
  local projects = {}
  for _, project in ipairs(project_keys) do
    local members = grouped[project]
    table.sort(members, function(a, b)
      return a.id < b.id
    end)

    local member_ids = {}
    local manifest_members = {}
    for _, member in ipairs(members) do
      member_ids[member.id] = true
      manifest_members[#manifest_members + 1] = {
        id = member.id,
        path = "note/" .. member.id .. ".typ",
      }
    end

    local referenced = {}
    for _, member in ipairs(members) do
      for _, target_id in ipairs(references_by_id[member.id] or {}) do
        if not member_ids[target_id] then
          referenced[target_id] = true
        end
      end
    end

    local reference_ids = vim.tbl_keys(referenced)
    table.sort(reference_ids)
    local references = {}
    for _, target_id in ipairs(reference_ids) do
      local target = notes[target_id]
      if target then
        references[#references + 1] = {
          id = target_id,
          title = target.title or target_id,
        }
      end
    end

    projects[#projects + 1] = {
      key = project,
      members = manifest_members,
      references = references,
    }
  end

  return vim.json.encode({
    version = 1,
    notes = manifest_notes,
    projects = projects,
  }) .. "\n"
end

local function update_projects_manifest()
  if not state.projects_dirty and state.last_projects_payload ~= nil then
    return true
  end

  local payload, build_err = build_projects_manifest()
  if not payload then
    return false, build_err
  end

  if state.last_projects_payload == nil then
    local existing = io.open(projects_manifest_path, "rb")
    if existing then
      state.last_projects_payload = existing:read("*a")
      existing:close()
    end
  end

  if payload ~= state.last_projects_payload then
    local ok, write_err = atomic_write(projects_manifest_path, payload)
    if not ok then
      return false, write_err
    end
    state.last_projects_payload = payload
  end
  state.projects_dirty = false
  return true
end

local function notify_manifest_changed()
  local params = {
    changes = {
      {
        uri = vim.uri_from_fname(manifest_path),
        type = 2,
      },
      -- Tinymist does not always invalidate a dynamic include when only its
      -- JSON input changes. Marking the stable main as changed forces a cheap
      -- re-evaluation without replacing or opening the main file.
      {
        uri = vim.uri_from_fname(focus_main),
        type = 2,
      },
    },
  }

  for _, client in ipairs(vim.lsp.get_clients({ name = "tinymist" })) do
    if normalize(client.root_dir) == wiki_root then
      client:notify("workspace/didChangeWatchedFiles", params)
    end
  end
end

local function build_manifest(bufnr, id)
  local current = state.notes and state.notes[id]
  if not current then
    return nil, string.format("zk-lsp did not index note %s", id)
  end
  if type(current.metadata) ~= "table" then
    return nil, string.format("zk-lsp returned no metadata for note %s", id)
  end

  local members, project = project_members(current)
  local member_ids = {}
  local manifest_members = {}
  for _, member in ipairs(members) do
    if type(member.metadata) ~= "table" then
      return nil, string.format("zk-lsp returned no metadata for project member %s", member.id)
    end
    member_ids[member.id] = true
    manifest_members[#manifest_members + 1] = {
      id = member.id,
      path = "note/" .. member.id .. ".typ",
      title = member.title or member.id,
      metadata = member.metadata,
    }
  end

  local referenced = {}
  for _, member in ipairs(members) do
    local ids, read_err = note_reference_ids(member, bufnr, id)
    if not ids then
      return nil, read_err
    end
    for _, target_id in ipairs(ids) do
      if not member_ids[target_id] then
        referenced[target_id] = true
      end
    end
  end

  local ids = vim.tbl_keys(referenced)
  table.sort(ids)
  local references = {}
  for _, target_id in ipairs(ids) do
    local target = state.notes and state.notes[target_id]
    if target then
      references[#references + 1] = {
        id = target_id,
        title = target.title or target_id,
      }
    end
  end

  local manifest = {
    version = 1,
    project = project,
    focus = {
      id = id,
      path = "note/" .. id .. ".typ",
      title = current.title or id,
      metadata = current.metadata,
    },
    members = manifest_members,
    references = references,
  }

  local ordered_member_ids = {}
  for _, member in ipairs(members) do
    ordered_member_ids[#ordered_member_ids + 1] = member.id
  end
  return vim.json.encode(manifest) .. "\n", nil, ids, ordered_member_ids, project
end

local function update_manifest(bufnr, id)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false, "focus buffer is no longer valid"
  end

  local projects_ok, projects_err = update_projects_manifest()
  if not projects_ok then
    return false, projects_err
  end

  local payload, err, ids, member_ids, project = build_manifest(bufnr, id)
  if not payload then
    return false, err
  end

  if state.last_payload == nil then
    local existing = io.open(manifest_path, "rb")
    if existing then
      state.last_payload = existing:read("*a")
      existing:close()
    end
  end

  if payload ~= state.last_payload then
    local ok, write_err = atomic_write(manifest_path, payload)
    if not ok then
      return false, write_err
    end
    state.last_payload = payload
    notify_manifest_changed()
  end

  state.last_member_ids = member_ids
  state.last_project = project
  state.last_reference_ids = ids
  state.last_error = nil
  state.last_notified_error = nil
  return true
end

local function report_error(err)
  if not err or err == "focus update was superseded" then
    return
  end
  state.last_error = err
  if state.last_notified_error == err then
    return
  end
  state.last_notified_error = err
  vim.notify("Tinymist ZK focus: " .. err, vim.log.levels.WARN)
end

function M.update(bufnr, opts, callback)
  bufnr = bufnr or 0
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  opts = opts or {}
  callback = callback or function() end

  local id = note_id_from_buffer(bufnr)
  if not id then
    callback(false, "buffer is not a wiki note")
    return
  end

  if opts.activate ~= false then
    state.active_buf = bufnr
    state.active_id = id
    state.generation = state.generation + 1
  end
  local generation = state.generation

  local function finish(ok, err)
    if generation ~= state.generation or state.active_buf ~= bufnr then
      callback(false, "focus update was superseded")
      return
    end
    if not ok then
      report_error(err)
      callback(false, err)
      return
    end

    local updated, update_err = update_manifest(bufnr, id)
    if not updated then
      report_error(update_err)
    end
    callback(updated, update_err, manifest_path)
  end

  load_notes(opts.force_notes == true, function(ok, err)
    if ok and state.notes[id] then
      finish(true)
      return
    end

    if ok and not opts._retried then
      state.notes = nil
      load_notes(true, function(retry_ok, retry_err)
        finish(retry_ok, retry_err or ("zk-lsp did not index note " .. id))
      end)
      return
    end

    finish(false, err or ("zk-lsp did not index note " .. id))
  end)
end

local function schedule_active_update()
  local bufnr = state.active_buf
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if not state.timer then
    state.timer = uv.new_timer()
  end
  state.timer:stop()
  state.timer:start(
    250,
    0,
    vim.schedule_wrap(function()
      if state.active_buf == bufnr and note_id_from_buffer(bufnr) then
        M.update(bufnr, { activate = false })
      end
    end)
  )
end

function M.setup()
  if state.setup then
    return
  end
  state.setup = true

  local group = vim.api.nvim_create_augroup("ZkTinymistFocus", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(event)
      if note_id_from_buffer(event.buf) then
        M.update(event.buf)
      end
    end,
    desc = "Focus Tinymist on the current ZK note",
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(event)
      local path = normalize(vim.api.nvim_buf_get_name(event.buf))
      local id = note_id_from_path(path)
      if path == vim.fs.joinpath(wiki_root, "metadata.toml") or id then
        state.notes = nil
      end
      if state.active_buf and vim.api.nvim_buf_is_valid(state.active_buf) then
        if path == vim.fs.joinpath(wiki_root, "metadata.toml") or id then
          M.update(state.active_buf, { activate = false, force_notes = true })
        end
      end
    end,
    desc = "Refresh focused ZK project metadata and external title stubs after writes",
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(event)
      if event.buf == state.active_buf and note_id_from_buffer(event.buf) then
        schedule_active_update()
      end
    end,
    desc = "Refresh external-reference stubs after ZK link edits",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if state.timer then
        state.timer:stop()
        state.timer:close()
        state.timer = nil
      end
    end,
  })

  pcall(vim.api.nvim_del_user_command, "ZkFocusRefresh")
  vim.api.nvim_create_user_command("ZkFocusRefresh", function()
    local bufnr = vim.api.nvim_get_current_buf()
    M.update(bufnr, { force_notes = true }, function(ok, err)
      if ok then
        vim.notify("Tinymist ZK focus refreshed")
      else
        report_error(err)
      end
    end)
  end, { desc = "Regenerate the current Tinymist ZK project manifest" })
end

function M.ensure_projects(callback)
  callback = callback or function() end
  load_notes(false, function(ok, err)
    if not ok then
      callback(false, err)
      return
    end
    local updated, update_err = update_projects_manifest()
    callback(updated, update_err, projects_manifest_path)
  end)
end

function M.is_wiki_note_path(path)
  return note_id_from_path(path) ~= nil
end

function M.note_id(bufnr)
  return note_id_from_buffer(bufnr)
end

function M.focus_main()
  return focus_main
end

function M.wiki_root()
  return wiki_root
end

function M.is_active(bufnr)
  return state.active_buf == bufnr and note_id_from_buffer(bufnr) == state.active_id
end

function M.status()
  return {
    active_buf = state.active_buf,
    active_id = state.active_id,
    focus_main = focus_main,
    last_error = state.last_error,
    manifest_path = manifest_path,
    member_ids = vim.deepcopy(state.last_member_ids),
    note_count = state.notes and vim.tbl_count(state.notes) or 0,
    project = state.last_project,
    projects_manifest_path = projects_manifest_path,
    reference_ids = vim.deepcopy(state.last_reference_ids),
  }
end

M._reference_ids = reference_ids

return M
