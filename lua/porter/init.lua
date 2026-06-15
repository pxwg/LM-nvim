local M = {}

local default_config = {
  override_paste = true,
  routes = {},
}

local state = {
  config = vim.deepcopy(default_config),
  metadata = {},
  info_seq = 0,
  setup_done = false,
}

local paste_commands = {
  p = true,
  P = true,
  gp = true,
  gP = true,
}

local plug_mappings = {
  p = { lhs = "<Plug>(porter-paste-after)", desc = "Porter paste after" },
  P = { lhs = "<Plug>(porter-paste-before)", desc = "Porter paste before" },
  gp = { lhs = "<Plug>(porter-paste-after-cursor)", desc = "Porter paste after and leave cursor after text" },
  gP = { lhs = "<Plug>(porter-paste-before-cursor)", desc = "Porter paste before and leave cursor after text" },
}

local native_paste_desc = {
  p = "Paste after through Porter",
  P = "Paste before through Porter",
  gp = "Paste after through Porter and leave cursor after text",
  gP = "Paste before through Porter and leave cursor after text",
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.WARN, { title = "porter.nvim" })
end

local function normalize_register(register)
  if register == nil or register == "" then
    return '"'
  end

  if register:match("%u") ~= nil then
    return register:lower()
  end

  return register
end

local function is_blackhole_register(register)
  return normalize_register(register) == "_"
end

local function get_buf_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return ""
  end
  return vim.fn.fnamemodify(name, ":p")
end

local function read_register(register)
  register = normalize_register(register)
  local ok_lines, lines = pcall(vim.fn.getreg, register, 1, true)
  local ok_type, regtype = pcall(vim.fn.getregtype, register)

  if not ok_lines then
    lines = {}
  end
  if type(lines) == "string" then
    lines = { lines }
  end
  if type(lines) ~= "table" then
    lines = {}
  end

  return {
    register = register,
    lines = lines,
    text = table.concat(lines, "\n"),
    regtype = ok_type and regtype or "v",
  }
end

local function set_register(register, value, regtype)
  register = normalize_register(register)
  return vim.fn.setreg(register, value, regtype)
end

local function hash_register(lines, regtype)
  local ok, encoded = pcall(vim.json.encode, {
    lines = lines or {},
    regtype = regtype or "v",
  })

  if not ok then
    encoded = table.concat(lines or {}, "\n") .. "\0" .. tostring(regtype or "v")
  end

  return vim.fn.sha256(encoded)
end

local function changedtick(bufnr)
  local ok, tick = pcall(vim.api.nvim_buf_get_changedtick, bufnr)
  return ok and tick or nil
end

local function source_context(bufnr)
  local start_mark = vim.api.nvim_buf_get_mark(bufnr, "[")
  local finish_mark = vim.api.nvim_buf_get_mark(bufnr, "]")

  return {
    bufnr = bufnr,
    path = get_buf_path(bufnr),
    filetype = vim.bo[bufnr].filetype,
    buftype = vim.bo[bufnr].buftype,
    start = { line = start_mark[1], col = start_mark[2] + 1 },
    finish = { line = finish_mark[1], col = finish_mark[2] + 1 },
    changedtick = changedtick(bufnr),
  }
end

local function target_context()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)

  return {
    bufnr = bufnr,
    path = get_buf_path(bufnr),
    filetype = vim.bo[bufnr].filetype,
    buftype = vim.bo[bufnr].buftype,
    cursor = { line = cursor[1], col = cursor[2] + 1 },
  }
end

local function metadata_for_register(register, source, event, time)
  local current = read_register(register)

  return {
    register = current.register,
    regtype = current.regtype,
    inclusive = event.inclusive,
    text = current.text,
    hash = hash_register(current.lines, current.regtype),
    source = vim.deepcopy(source),
    time = time,
  }
end

local function yank_registers(regname)
  local register = normalize_register(regname)

  if is_blackhole_register(register) then
    return {}
  end

  if regname == nil or regname == "" or regname == '"' then
    return { '"', "0" }
  end

  if register == "0" then
    return { "0", '"' }
  end

  return { register, '"' }
end

local function store_yank_metadata(event)
  if event == nil or event.operator ~= "y" then
    return
  end

  local source = source_context(vim.api.nvim_get_current_buf())
  local now = os.time()

  for _, register in ipairs(yank_registers(event.regname)) do
    state.metadata[register] = metadata_for_register(register, source, event, now)
  end
end

local function string_starts_with(value, prefix)
  return value:sub(1, #prefix) == prefix
end

local function string_ends_with(value, suffix)
  return suffix == "" or value:sub(-#suffix) == suffix
end

local function match_scalar(actual, expected, ctx)
  if expected == nil then
    return true
  end

  if type(expected) == "function" then
    local ok, result = pcall(expected, actual, ctx)
    return ok and result == true
  end

  if type(expected) ~= "table" then
    return actual == expected
  end

  if expected.equals ~= nil and actual ~= expected.equals then
    return false
  end
  if expected.pattern ~= nil and tostring(actual or ""):match(expected.pattern) == nil then
    return false
  end
  if expected.contains ~= nil and tostring(actual or ""):find(expected.contains, 1, true) == nil then
    return false
  end
  if expected.prefix ~= nil and not string_starts_with(tostring(actual or ""), expected.prefix) then
    return false
  end
  if expected.suffix ~= nil and not string_ends_with(tostring(actual or ""), expected.suffix) then
    return false
  end

  if #expected > 0 then
    for _, item in ipairs(expected) do
      if actual == item then
        return true
      end
    end
    return false
  end

  return true
end

local function match_endpoint(endpoint, conditions, ctx)
  if conditions == nil then
    return true
  end

  for key, expected in pairs(conditions) do
    if not match_scalar(endpoint[key], expected, ctx) then
      return false
    end
  end

  return true
end

local function route_name(route)
  return route.name or "<unnamed>"
end

local function find_route(ctx)
  for _, route in ipairs(state.config.routes or {}) do
    if
      type(route) == "table"
      and type(route.transform) == "function"
      and match_endpoint(ctx.source, route.from, ctx)
      and match_endpoint(ctx.target, route.to, ctx)
    then
      return route
    end
  end

  return nil
end

local function native_keys(command, register, count, force_register)
  local keys = {}

  if count ~= nil and count > 0 then
    table.insert(keys, tostring(count))
  end

  register = normalize_register(register)
  if force_register or register ~= '"' then
    table.insert(keys, '"')
    table.insert(keys, register)
  end

  table.insert(keys, command)
  return table.concat(keys)
end

local function execute_native_paste(command, register, count, force_register)
  vim.cmd.normal({ bang = true, args = { native_keys(command, register, count, force_register) } })
end

local function resolve_metadata(paste_register)
  paste_register = normalize_register(paste_register)
  local current = read_register(paste_register)
  local current_hash = hash_register(current.lines, current.regtype)
  local direct = state.metadata[paste_register]

  if paste_register == '"' then
    local zero = state.metadata["0"]
    if zero ~= nil and zero.hash == current_hash then
      return zero, current, nil
    end
  end

  if direct ~= nil and direct.hash == current_hash then
    return direct, current, nil
  end

  if direct ~= nil then
    return nil, current, "hash_mismatch"
  end

  return nil, current, "no_metadata"
end

local function build_ctx(metadata, current)
  local ctx = {
    register = metadata.register,
    regtype = current.regtype,
    text = current.text,
    source = vim.deepcopy(metadata.source),
    target = target_context(),
  }

  return ctx
end

local function transform_result_to_register(result, fallback_regtype)
  if type(result) == "string" then
    return result, fallback_regtype
  end

  if type(result) == "table" and type(result.text) == "string" then
    return result.text, result.regtype or fallback_regtype
  end

  return nil, nil
end

local function paste_with_transformed_register(command, paste_register, count, force_register, text, regtype)
  local saved = read_register(paste_register)
  local ok, err = xpcall(function()
    set_register(paste_register, text, regtype)
    execute_native_paste(command, paste_register, count, force_register)
  end, debug.traceback)

  local restore_ok, restore_err = pcall(set_register, paste_register, saved.lines, saved.regtype)
  if not restore_ok then
    notify(("failed to restore register %s: %s"):format(paste_register, restore_err), vim.log.levels.ERROR)
  end

  if not ok then
    notify(("native paste failed: %s"):format(err), vim.log.levels.ERROR)
  end

  return ok
end

function M.paste(command, opts)
  opts = opts or {}
  if not paste_commands[command] then
    error("unsupported porter paste command: " .. tostring(command))
  end

  local paste_register = normalize_register(opts.register or vim.v.register)
  local count = opts.count
  if count == nil then
    count = vim.v.count > 0 and vim.v.count or nil
  end
  local force_register = opts.force_register == true

  local metadata, current = resolve_metadata(paste_register)
  if metadata == nil then
    execute_native_paste(command, paste_register, count, force_register)
    return false
  end

  local ctx = build_ctx(metadata, current)
  local route = find_route(ctx)

  if route == nil then
    execute_native_paste(command, paste_register, count, force_register)
    return false
  end

  ctx.route = { name = route_name(route) }

  local ok, result = xpcall(function()
    return route.transform(ctx)
  end, debug.traceback)

  if not ok then
    notify(("route %s failed: %s"):format(route_name(route), result), vim.log.levels.ERROR)
    execute_native_paste(command, paste_register, count, force_register)
    return false
  end

  local transformed_text, transformed_regtype = transform_result_to_register(result, current.regtype)
  if transformed_text == nil then
    notify(("route %s returned an invalid transform result"):format(route_name(route)), vim.log.levels.ERROR)
    execute_native_paste(command, paste_register, count, force_register)
    return false
  end

  return paste_with_transformed_register(
    command,
    paste_register,
    count,
    force_register,
    transformed_text,
    transformed_regtype
  )
end

local function metadata_preview(metadata)
  if metadata == nil then
    return nil
  end

  local preview = metadata.text:gsub("\n", "\\n")
  if #preview > 160 then
    preview = preview:sub(1, 157) .. "..."
  end

  return {
    register = metadata.register,
    regtype = metadata.regtype,
    inclusive = metadata.inclusive,
    hash = metadata.hash,
    text_length = #metadata.text,
    text_preview = preview,
    source = metadata.source,
    time = metadata.time,
  }
end

function M.info(register)
  local target = target_context()
  local paste_register = normalize_register(register or vim.v.register)
  local metadata, current, invalid_reason = resolve_metadata(paste_register)
  local stale_metadata = state.metadata[paste_register]
  local ctx = metadata ~= nil
      and {
        register = metadata.register,
        regtype = current.regtype,
        text = current.text,
        source = vim.deepcopy(metadata.source),
        target = target,
      }
    or nil
  local route = ctx ~= nil and find_route(ctx) or nil

  if metadata ~= nil and route == nil then
    invalid_reason = "no_route"
  end

  return {
    register = paste_register,
    current = {
      regtype = current.regtype,
      hash = hash_register(current.lines, current.regtype),
      text_length = #current.text,
    },
    valid = metadata ~= nil and route ~= nil,
    invalid_reason = invalid_reason,
    metadata = metadata_preview(metadata or stale_metadata),
    target = target,
    matched_route = route ~= nil and { name = route_name(route) } or nil,
  }
end

local function open_info_window(info)
  local lines = vim.split(vim.inspect(info), "\n", { plain = true })
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "lua"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.cmd("botright 16new")
  vim.api.nvim_win_set_buf(0, buf)
  state.info_seq = state.info_seq + 1
  vim.api.nvim_buf_set_name(buf, ("porter://info/%d"):format(state.info_seq))
end

local function create_commands()
  pcall(vim.api.nvim_del_user_command, "PorterInfo")
  vim.api.nvim_create_user_command("PorterInfo", function(opts)
    open_info_window(M.info(opts.args ~= "" and opts.args or nil))
  end, {
    nargs = "?",
    desc = "Show porter.nvim metadata and route match for a register",
  })
end

local function create_autocmds()
  local group = vim.api.nvim_create_augroup("Porter", { clear = true })
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = function()
      store_yank_metadata(vim.v.event)
    end,
  })
end

local function create_plug_mappings()
  for command, mapping in pairs(plug_mappings) do
    vim.keymap.set("n", mapping.lhs, function()
      M.paste(command)
    end, { silent = true, desc = mapping.desc })
  end
end

local function create_override_mappings()
  for command, mapping in pairs(plug_mappings) do
    vim.keymap.set("n", command, mapping.lhs, {
      remap = true,
      silent = true,
      desc = native_paste_desc[command],
    })
  end
end

local function remove_override_mappings()
  for command, desc in pairs(native_paste_desc) do
    local mapping = vim.fn.maparg(command, "n", false, true)
    if type(mapping) == "table" and mapping.desc == desc then
      pcall(vim.keymap.del, "n", command)
    end
  end
end

function M.setup(opts)
  state.config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})
  state.metadata = {}
  state.setup_done = true

  create_autocmds()
  create_plug_mappings()
  if state.config.override_paste then
    create_override_mappings()
  else
    remove_override_mappings()
  end
  create_commands()
end

function M._on_yank(event)
  store_yank_metadata(event)
end

function M._state()
  return state
end

function M._reset()
  state.config = vim.deepcopy(default_config)
  state.metadata = {}
  state.info_seq = 0
  state.setup_done = false
  pcall(vim.api.nvim_del_augroup_by_name, "Porter")
  pcall(vim.api.nvim_del_user_command, "PorterInfo")
  remove_override_mappings()
end

return M
