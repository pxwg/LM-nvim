local M = {}

local uv = vim.uv or vim.loop
local wiki_root = vim.fs.normalize(vim.fn.expand("~/wiki"))
local note_root = vim.fs.joinpath(wiki_root, "note")
local focus_main = vim.fs.joinpath(wiki_root, "focus.typ")
local manifest_path = vim.fs.joinpath(wiki_root, ".zk-lsp", "focus-v1.json")

local state = {
  active_buf = nil,
  active_id = nil,
  generation = 0,
  last_error = nil,
  last_notified_error = nil,
  last_payload = nil,
  last_reference_ids = {},
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

local function reference_ids(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
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

local function finish_notes_load(notes, err)
  state.loading_notes = false
  if notes then
    state.notes = notes
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

  local references = {}
  local ids = reference_ids(bufnr)
  for _, target_id in ipairs(ids) do
    if target_id ~= id then
      local target = state.notes[target_id]
      if target then
        references[#references + 1] = {
          id = target_id,
          title = target.title or target_id,
        }
      end
    end
  end

  local manifest = {
    version = 1,
    focus = {
      id = id,
      path = "note/" .. id .. ".typ",
      title = current.title or id,
      metadata = current.metadata,
    },
    references = references,
  }

  return vim.json.encode(manifest) .. "\n", nil, ids
end

local function update_manifest(bufnr, id)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false, "focus buffer is no longer valid"
  end

  local payload, err, ids = build_manifest(bufnr, id)
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
        if path == vim.fs.joinpath(wiki_root, "metadata.toml") or event.buf == state.active_buf then
          M.update(state.active_buf, { activate = false, force_notes = true })
        end
      end
    end,
    desc = "Refresh focused ZK metadata and title stubs after writes",
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(event)
      if event.buf == state.active_buf and note_id_from_buffer(event.buf) then
        schedule_active_update()
      end
    end,
    desc = "Refresh direct-reference stubs after ZK link edits",
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
  end, { desc = "Regenerate the current Tinymist ZK focus manifest" })
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
    note_count = state.notes and vim.tbl_count(state.notes) or 0,
    reference_ids = vim.deepcopy(state.last_reference_ids),
  }
end

M._reference_ids = reference_ids

return M
