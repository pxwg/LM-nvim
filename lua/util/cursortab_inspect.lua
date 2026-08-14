local M = {}

local ns = vim.api.nvim_create_namespace("cursortab_inspect")
local config
local setup_done = false
local ensure_running = false

local ui = {
  tab = nil,
  list_buf = nil,
  list_win = nil,
  detail_buf = nil,
  detail_win = nil,
  traces = {},
  selected = 1,
  list_lines = {},
  raw = false,
  signature = nil,
  timer = nil,
}

local defaults = {
  host = "127.0.0.1",
  port = 19198,
  upstream_base = "https://api.deepseek.com",
  allowed_path = "/beta/completions",
  max_entries = 200,
  state_dir = vim.fn.stdpath("state") .. "/cursortab-inspect",
}

local function setup_highlights()
  local highlights = {
    CursorTabInspectTitle = "Title",
    CursorTabInspectSection = "Function",
    CursorTabInspectSuccess = "DiagnosticOk",
    CursorTabInspectError = "DiagnosticError",
    CursorTabInspectAccent = "DiagnosticWarn",
    CursorTabInspectMuted = "Comment",
    CursorTabInspectKey = "Identifier",
    CursorTabInspectValue = "String",
    CursorTabInspectCode = "Normal",
    CursorTabInspectBorder = "FloatBorder",
  }
  for name, link in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, { default = true, link = link })
  end
end

local function project_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))
end

local function paths()
  local state_dir = vim.fn.expand(config.state_dir)
  return {
    state_dir = state_dir,
    trace = vim.fs.joinpath(state_dir, "exchanges.jsonl"),
    pid = vim.fs.joinpath(state_dir, "proxy.pid"),
    log = vim.fs.joinpath(state_dir, "proxy.log"),
    script = vim.fs.joinpath(project_root(), "script", "cursortab_inspect_proxy.py"),
  }
end

local function proxy_command(mode)
  local p = paths()
  return {
    "python3",
    p.script,
    mode,
    "--host",
    config.host,
    "--port",
    tostring(config.port),
    "--upstream-base",
    config.upstream_base,
    "--allowed-path",
    config.allowed_path,
    "--trace-file",
    p.trace,
    "--pid-file",
    p.pid,
    "--log-file",
    p.log,
  }
end

local function notify_proxy_failure(result)
  local message = result.stderr ~= "" and result.stderr or result.stdout
  vim.notify("CursorTab inspect proxy failed: " .. vim.trim(message or "unknown error"), vim.log.levels.ERROR)
end

local function ensure_proxy_sync()
  local result = vim.system(proxy_command("--ensure"), { text = true }):wait(4000)
  if result.code ~= 0 then
    notify_proxy_failure(result)
    return false
  end
  return true
end

function M.ensure_proxy(callback)
  if ensure_running then
    return
  end
  ensure_running = true
  vim.system(proxy_command("--ensure"), { text = true }, function(result)
    vim.schedule(function()
      ensure_running = false
      if result.code ~= 0 then
        notify_proxy_failure(result)
      end
      if callback then
        callback(result.code == 0)
      end
    end)
  end)
end

function M.provider_url()
  return string.format("http://%s:%d/beta", config.host, config.port)
end

local function set_buffer_lines(buf, lines)
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function json_scalar(value)
  if type(value) == "string" then
    return value
  end
  if type(value) == "table" then
    return vim.json.encode(value)
  end
  return tostring(value)
end

local function pretty_json(value, level)
  level = level or 0
  local indent = string.rep("  ", level)
  local child_indent = string.rep("  ", level + 1)
  if type(value) ~= "table" then
    return { vim.json.encode(value) }
  end

  if vim.islist(value) then
    if #value == 0 then
      return { "[]" }
    end
    local lines = { "[" }
    for index, item in ipairs(value) do
      local child = pretty_json(item, level + 1)
      child[1] = child_indent .. child[1]
      for child_index = 2, #child do
        child[child_index] = child_indent .. child[child_index]
      end
      if index < #value then
        child[#child] = child[#child] .. ","
      end
      vim.list_extend(lines, child)
    end
    table.insert(lines, indent .. "]")
    return lines
  end

  local keys = vim.tbl_keys(value)
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)
  if #keys == 0 then
    return { "{}" }
  end

  local lines = { "{" }
  for index, key in ipairs(keys) do
    local child = pretty_json(value[key], level + 1)
    local prefix = child_indent .. vim.json.encode(tostring(key)) .. ": "
    child[1] = prefix .. child[1]
    for child_index = 2, #child do
      child[child_index] = child_indent .. child[child_index]
    end
    if index < #keys then
      child[#child] = child[#child] .. ","
    end
    vim.list_extend(lines, child)
  end
  table.insert(lines, indent .. "}")
  return lines
end

local function decode_trace(line, sequence)
  local ok, trace = pcall(vim.json.decode, line)
  if not ok or type(trace) ~= "table" then
    return nil
  end
  trace._sequence = sequence
  return trace
end

local function load_traces()
  local trace_path = paths().trace
  if vim.fn.filereadable(trace_path) == 0 then
    return {}, "0"
  end

  local raw_lines = vim.fn.readfile(trace_path)
  local first = math.max(1, #raw_lines - config.max_entries + 1)
  local traces = {}
  for line_number = first, #raw_lines do
    local trace = decode_trace(raw_lines[line_number], line_number)
    if trace then
      table.insert(traces, 1, trace)
    end
  end
  local newest = traces[1] and traces[1].id or ""
  return traces, string.format("%d:%s", #raw_lines, newest)
end

local function response_status(trace)
  return tonumber(vim.tbl_get(trace, "response", "status")) or 0
end

local function current_timeout_ms()
  local ok, cursortab_config = pcall(require, "cursortab.config")
  if not ok then
    return nil
  end
  return tonumber(cursortab_config.get().provider.completion_timeout)
end

local function downstream_delivery(trace)
  local downstream = trace.downstream
  if type(downstream) ~= "table" then
    return nil
  end
  return downstream.delivered
end

local function trace_outcome(trace)
  local status = response_status(trace)
  local delivered = downstream_delivery(trace)
  local timeout = current_timeout_ms()
  local duration = tonumber(trace.duration_ms) or 0
  if status < 200 or status >= 300 then
    return { label = "HTTP ERROR", marker = "×", group = "CursorTabInspectError" }
  end
  if delivered == false then
    return { label = "NOT DELIVERED", marker = "×", group = "CursorTabInspectError" }
  end
  if timeout and duration > timeout then
    return { label = "LATE UPSTREAM", marker = "◷", group = "CursorTabInspectAccent" }
  end
  if delivered == true then
    return { label = "DELIVERED", marker = "●", group = "CursorTabInspectSuccess" }
  end
  return { label = "UPSTREAM OK", marker = "◆", group = "CursorTabInspectAccent" }
end

local function trace_model(trace)
  return vim.tbl_get(trace, "request", "body", "model") or "unknown model"
end

local function trace_time(trace)
  local timestamp = trace.started_at or ""
  local clock = timestamp:match("T(%d%d:%d%d:%d%d)")
  if not clock then
    return timestamp
  end
  return clock .. (vim.endswith(timestamp, "Z") and "Z" or "")
end

local function prompt_summary(trace)
  local prompt = vim.tbl_get(trace, "request", "body", "prompt") or ""
  for _, line in ipairs(vim.split(prompt, "\n", { plain = true })) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      if vim.fn.strdisplaywidth(trimmed) > 38 then
        return vim.fn.strcharpart(trimmed, 0, 37) .. "…"
      end
      return trimmed
    end
  end
  return "empty prompt"
end

local function add_highlight(buf, group, line, start_col, end_col)
  vim.api.nvim_buf_add_highlight(buf, ns, group, line - 1, start_col or 0, end_col or -1)
end

local function valid_ui()
  return ui.tab
    and vim.api.nvim_tabpage_is_valid(ui.tab)
    and ui.list_buf
    and vim.api.nvim_buf_is_valid(ui.list_buf)
    and ui.detail_buf
    and vim.api.nvim_buf_is_valid(ui.detail_buf)
end

local function render_list()
  if not valid_ui() then
    return
  end

  local list_width = ui.list_win and vim.api.nvim_win_is_valid(ui.list_win) and vim.api.nvim_win_get_width(ui.list_win)
    or 46
  local lines = {
    " CursorTab Inspect",
    string.format(" %d captured FIM exchange%s", #ui.traces, #ui.traces == 1 and "" or "s"),
    " " .. string.rep("─", math.max(1, list_width - 2)),
  }
  local highlights = {
    { "CursorTabInspectTitle", 1 },
    { "CursorTabInspectMuted", 2 },
    { "CursorTabInspectBorder", 3 },
  }
  ui.list_lines = {}

  if #ui.traces == 0 then
    vim.list_extend(lines, {
      "",
      " No requests captured yet.",
      "",
      " Edit a file and wait for a CursorTab suggestion.",
      " Press r to refresh.",
    })
    table.insert(highlights, { "CursorTabInspectMuted", 5 })
    table.insert(highlights, { "CursorTabInspectMuted", 7 })
    table.insert(highlights, { "CursorTabInspectMuted", 8 })
  else
    for index, trace in ipairs(ui.traces) do
      local status = response_status(trace)
      local outcome = trace_outcome(trace)
      local duration = tonumber(trace.duration_ms) or 0
      local main_line = #lines + 1
      table.insert(
        lines,
        string.format(
          " %s  #%d  %s  %d  %.0fms",
          outcome.marker,
          trace._sequence or index,
          trace_time(trace),
          status,
          duration
        )
      )
      table.insert(lines, string.format("    %s · %s", trace_model(trace), prompt_summary(trace)))
      table.insert(lines, "")
      ui.list_lines[index] = main_line
      table.insert(highlights, { outcome.group, main_line, 1, 4 })
      table.insert(highlights, { "CursorTabInspectMuted", main_line + 1 })
    end
  end

  vim.api.nvim_buf_clear_namespace(ui.list_buf, ns, 0, -1)
  set_buffer_lines(ui.list_buf, lines)
  for _, highlight in ipairs(highlights) do
    add_highlight(ui.list_buf, highlight[1], highlight[2], highlight[3], highlight[4])
  end

  if #ui.traces > 0 and ui.list_win and vim.api.nvim_win_is_valid(ui.list_win) then
    ui.selected = math.max(1, math.min(ui.selected, #ui.traces))
    vim.api.nvim_win_set_cursor(ui.list_win, { ui.list_lines[ui.selected], 0 })
  end
end

local function value_line(lines, highlights, key, value)
  local line = string.format("  %-18s %s", key, value)
  table.insert(lines, line)
  table.insert(highlights, { "CursorTabInspectKey", #lines, 2, 20 })
  table.insert(highlights, { "CursorTabInspectValue", #lines, 20, -1 })
end

local function section(lines, highlights, title)
  if #lines > 0 and lines[#lines] ~= "" then
    table.insert(lines, "")
  end
  table.insert(lines, title)
  table.insert(highlights, { "CursorTabInspectSection", #lines })
  local detail_width = ui.detail_win
      and vim.api.nvim_win_is_valid(ui.detail_win)
      and vim.api.nvim_win_get_width(ui.detail_win)
    or 72
  table.insert(lines, string.rep("─", math.max(1, detail_width - 2)))
  table.insert(highlights, { "CursorTabInspectBorder", #lines })
end

local function text_block(lines, highlights, text)
  local block = vim.split(text ~= "" and text or "∅", "\n", { plain = true })
  for _, line in ipairs(block) do
    table.insert(lines, "│ " .. line)
    table.insert(highlights, { "CursorTabInspectCode", #lines })
    table.insert(highlights, { "CursorTabInspectBorder", #lines, 0, 2 })
  end
end

local function response_text(trace)
  local body = vim.tbl_get(trace, "response", "body") or {}
  local choices = body.choices
  if type(choices) == "table" and type(choices[1]) == "table" then
    return choices[1].text or "", choices[1].finish_reason
  end
  local message = vim.tbl_get(body, "error", "message")
  return message or vim.json.encode(body), nil
end

local function render_raw_detail(trace, lines, highlights)
  section(lines, highlights, "RAW REQUEST PAYLOAD")
  text_block(lines, highlights, table.concat(pretty_json(vim.tbl_get(trace, "request", "body") or {}), "\n"))
  section(lines, highlights, "RAW RESPONSE")
  text_block(lines, highlights, table.concat(pretty_json(vim.tbl_get(trace, "response", "body") or {}), "\n"))
end

local function render_strategy_detail(trace, lines, highlights)
  local request = vim.tbl_get(trace, "request", "body") or {}
  local response = vim.tbl_get(trace, "response", "body") or {}
  local usage = response.usage or {}
  local generated, finish_reason = response_text(trace)

  section(lines, highlights, "OVERVIEW")
  value_line(lines, highlights, "Model", tostring(request.model or ""))
  value_line(lines, highlights, "Endpoint", vim.tbl_get(trace, "request", "upstream_url") or "")
  value_line(lines, highlights, "Duration", string.format("%.2f ms", tonumber(trace.duration_ms) or 0))
  value_line(lines, highlights, "HTTP status", tostring(response_status(trace)))
  local delivered = downstream_delivery(trace)
  local delivery_text = delivered == true and "yes"
    or (delivered == false and "no — CursorTab canceled or closed the request")
    or "unknown — captured before delivery tracking"
  value_line(lines, highlights, "Delivered", delivery_text)
  local timeout = current_timeout_ms()
  value_line(lines, highlights, "CursorTab timeout", timeout and string.format("%d ms", timeout) or "—")
  local duration = tonumber(trace.duration_ms) or 0
  local timing = timeout and duration > timeout and string.format("late by %.2f ms", duration - timeout)
    or "within current timeout"
  value_line(lines, highlights, "Timing", timing)
  value_line(lines, highlights, "Finish reason", tostring(finish_reason or "—"))
  value_line(
    lines,
    highlights,
    "Token usage",
    string.format(
      "%s prompt + %s completion = %s total",
      tostring(usage.prompt_tokens or "—"),
      tostring(usage.completion_tokens or "—"),
      tostring(usage.total_tokens or "—")
    )
  )

  section(lines, highlights, "REQUEST OPTIONS")
  local keys = {}
  for key in pairs(request) do
    if key ~= "prompt" and key ~= "suffix" then
      table.insert(keys, key)
    end
  end
  table.sort(keys)
  for _, key in ipairs(keys) do
    value_line(lines, highlights, key, json_scalar(request[key]))
  end

  local prompt = request.prompt or ""
  local suffix = request.suffix or ""
  section(lines, highlights, string.format("PROMPT · BEFORE CURSOR · %d chars", #prompt))
  text_block(lines, highlights, prompt)

  table.insert(lines, "")
  table.insert(lines, "▼  DEEPSEEK GENERATES THE MISSING MIDDLE HERE")
  table.insert(highlights, { "CursorTabInspectAccent", #lines })

  section(lines, highlights, string.format("SUFFIX · AFTER CURSOR · %d chars", #suffix))
  text_block(lines, highlights, suffix)

  section(lines, highlights, string.format("MODEL INSERTION · %d chars", #generated))
  text_block(lines, highlights, generated)
end

local function render_detail()
  if not valid_ui() then
    return
  end
  vim.api.nvim_buf_clear_namespace(ui.detail_buf, ns, 0, -1)
  if #ui.traces == 0 then
    set_buffer_lines(ui.detail_buf, {
      "CursorTab Request Inspector",
      "",
      "Captured DeepSeek FIM requests will appear here automatically.",
      "The Authorization header is always redacted before writing traces.",
    })
    add_highlight(ui.detail_buf, "CursorTabInspectTitle", 1)
    add_highlight(ui.detail_buf, "CursorTabInspectMuted", 3)
    add_highlight(ui.detail_buf, "CursorTabInspectMuted", 4)
    return
  end

  local trace = ui.traces[ui.selected]
  local status = response_status(trace)
  local outcome = trace_outcome(trace)
  local lines = {
    string.format("CursorTab Request #%d", trace._sequence or ui.selected),
    string.format(
      "%s %s  ·  HTTP %d  ·  %s  ·  %.0f ms",
      outcome.marker,
      outcome.label,
      status,
      trace.started_at or "",
      tonumber(trace.duration_ms) or 0
    ),
    "R raw/strategy  ·  y request JSON  ·  Y response JSON  ·  r refresh  ·  q close",
  }
  local highlights = {
    { "CursorTabInspectTitle", 1 },
    { outcome.group, 2 },
    { "CursorTabInspectMuted", 3 },
  }

  if ui.raw then
    render_raw_detail(trace, lines, highlights)
  else
    render_strategy_detail(trace, lines, highlights)
  end

  set_buffer_lines(ui.detail_buf, lines)
  for _, highlight in ipairs(highlights) do
    add_highlight(ui.detail_buf, highlight[1], highlight[2], highlight[3], highlight[4])
  end
end

local function select_trace(index)
  if #ui.traces == 0 then
    return
  end
  ui.selected = math.max(1, math.min(index, #ui.traces))
  if ui.list_win and vim.api.nvim_win_is_valid(ui.list_win) then
    vim.api.nvim_win_set_cursor(ui.list_win, { ui.list_lines[ui.selected], 0 })
  end
  render_detail()
end

function M.refresh(force)
  local old_trace = ui.traces[ui.selected]
  local old_id = old_trace and old_trace.id
  local followed_newest = ui.selected == 1
  local traces, signature = load_traces()
  if not force and signature == ui.signature then
    return
  end

  ui.traces = traces
  ui.signature = signature
  if followed_newest then
    ui.selected = 1
  elseif old_id then
    ui.selected = 1
    for index, trace in ipairs(traces) do
      if trace.id == old_id then
        ui.selected = index
        break
      end
    end
  end
  render_list()
  render_detail()
end

local function current_trace()
  return ui.traces[ui.selected]
end

local function yank_json(value, label)
  if value == nil then
    return
  end
  vim.fn.setreg("+", table.concat(pretty_json(value), "\n"))
  vim.notify("Copied CursorTab " .. label .. " JSON", vim.log.levels.INFO)
end

local function close_ui()
  if ui.tab and vim.api.nvim_tabpage_is_valid(ui.tab) then
    vim.api.nvim_set_current_tabpage(ui.tab)
    vim.cmd("tabclose")
  end
end

local function show_help()
  vim.notify(
    table.concat({
      "CursorTab Inspect",
      "j/k or C-n/C-p: next/previous request",
      "Enter/l: focus detail, h: focus request list",
      "R: toggle strategy/raw JSON, y/Y: copy request/response",
      "r: refresh, x: clear traces, q: close",
    }, "\n"),
    vim.log.levels.INFO
  )
end

local function clear_trace_file()
  local trace_path = paths().trace
  vim.fn.writefile({}, trace_path)
  pcall(vim.uv.fs_chmod, trace_path, 384)
end

local function clear_traces()
  if vim.fn.confirm("Clear all captured CursorTab exchanges?", "&Clear\n&Cancel", 2) ~= 1 then
    return
  end
  clear_trace_file()
  ui.signature = nil
  M.refresh(true)
end

local function map_ui_keys(buf, is_list)
  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true, desc = desc })
  end
  map("q", close_ui, "Close CursorTab inspector")
  map("r", function()
    M.refresh(true)
  end, "Refresh CursorTab traces")
  map("R", function()
    ui.raw = not ui.raw
    render_detail()
  end, "Toggle raw CursorTab JSON")
  map("y", function()
    yank_json(vim.tbl_get(current_trace() or {}, "request", "body"), "request")
  end, "Copy CursorTab request JSON")
  map("Y", function()
    yank_json(vim.tbl_get(current_trace() or {}, "response", "body"), "response")
  end, "Copy CursorTab response JSON")
  map("x", clear_traces, "Clear CursorTab traces")
  map("?", show_help, "Show CursorTab inspector help")
  map("h", function()
    if ui.list_win and vim.api.nvim_win_is_valid(ui.list_win) then
      vim.api.nvim_set_current_win(ui.list_win)
    end
  end, "Focus request list")
  map("l", function()
    if ui.detail_win and vim.api.nvim_win_is_valid(ui.detail_win) then
      vim.api.nvim_set_current_win(ui.detail_win)
    end
  end, "Focus request detail")

  if is_list then
    map("j", function()
      select_trace(ui.selected + 1)
    end, "Next CursorTab request")
    map("<C-n>", function()
      select_trace(ui.selected + 1)
    end, "Next CursorTab request")
    map("k", function()
      select_trace(ui.selected - 1)
    end, "Previous CursorTab request")
    map("<C-p>", function()
      select_trace(ui.selected - 1)
    end, "Previous CursorTab request")
    map("gg", function()
      select_trace(1)
    end, "Newest CursorTab request")
    map("G", function()
      select_trace(#ui.traces)
    end, "Oldest CursorTab request")
    map("<CR>", function()
      if ui.detail_win and vim.api.nvim_win_is_valid(ui.detail_win) then
        vim.api.nvim_set_current_win(ui.detail_win)
      end
    end, "Open CursorTab request detail")
  end
end

local function configure_buffer(buf, name, filetype)
  pcall(vim.api.nvim_buf_set_name, buf, name)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })
end

local function start_refresh_timer()
  if ui.timer then
    ui.timer:stop()
    ui.timer:close()
  end
  ui.timer = vim.uv.new_timer()
  ui.timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      if not valid_ui() then
        if ui.timer then
          ui.timer:stop()
          ui.timer:close()
          ui.timer = nil
        end
        return
      end
      M.refresh(false)
    end)
  )
end

function M.open()
  if valid_ui() then
    vim.api.nvim_set_current_tabpage(ui.tab)
    vim.api.nvim_set_current_win(ui.list_win)
    M.refresh(true)
    return
  end

  vim.cmd("tabnew")
  ui.tab = vim.api.nvim_get_current_tabpage()
  ui.list_win = vim.api.nvim_get_current_win()
  ui.list_buf = vim.api.nvim_create_buf(false, true)
  configure_buffer(ui.list_buf, "cursortab://inspect/requests", "cursortabinspect")
  vim.api.nvim_win_set_buf(ui.list_win, ui.list_buf)

  vim.cmd("vsplit")
  ui.detail_win = vim.api.nvim_get_current_win()
  ui.detail_buf = vim.api.nvim_create_buf(false, true)
  configure_buffer(ui.detail_buf, "cursortab://inspect/detail", "cursortabinspect")
  vim.api.nvim_win_set_buf(ui.detail_win, ui.detail_buf)
  local desired_list_width = math.min(46, math.max(32, math.floor(vim.o.columns * 0.34)))
  local list_width = math.min(desired_list_width, math.max(20, vim.o.columns - 30))
  vim.api.nvim_win_set_width(ui.list_win, list_width)

  vim.api.nvim_set_option_value("number", false, { win = ui.list_win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = ui.list_win })
  vim.api.nvim_set_option_value("cursorline", true, { win = ui.list_win })
  vim.api.nvim_set_option_value("wrap", false, { win = ui.list_win })
  vim.api.nvim_set_option_value("winfixwidth", true, { win = ui.list_win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = ui.list_win })

  vim.api.nvim_set_option_value("number", false, { win = ui.detail_win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = ui.detail_win })
  vim.api.nvim_set_option_value("wrap", false, { win = ui.detail_win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = ui.detail_win })
  vim.api.nvim_set_option_value("conceallevel", 0, { win = ui.detail_win })

  map_ui_keys(ui.list_buf, true)
  map_ui_keys(ui.detail_buf, false)
  ui.selected = 1
  ui.raw = false
  ui.signature = nil
  M.refresh(true)
  vim.api.nvim_set_current_win(ui.list_win)
  start_refresh_timer()
end

function M.clear()
  clear_trace_file()
  ui.signature = nil
  M.refresh(true)
end

function M.proxy_status()
  vim.system(proxy_command("--check"), { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("CursorTab inspect proxy is not running", vim.log.levels.WARN)
        return
      end
      local ok, status = pcall(vim.json.decode, result.stdout)
      if not ok then
        vim.notify("CursorTab inspect proxy returned invalid status", vim.log.levels.ERROR)
        return
      end
      vim.notify(
        string.format(
          "CursorTab inspect proxy running\nPID: %s\nEndpoint: http://%s:%d%s\nTrace: %s",
          tostring(status.pid),
          config.host,
          config.port,
          config.allowed_path,
          paths().trace
        ),
        vim.log.levels.INFO
      )
    end)
  end)
end

function M.restart_proxy()
  vim.system(proxy_command("--stop"), { text = true }, function()
    vim.schedule(function()
      M.ensure_proxy(function(ok)
        if ok then
          vim.notify("CursorTab inspect proxy restarted", vim.log.levels.INFO)
        end
      end)
    end)
  end)
end

local function create_commands()
  local commands = {
    CursortabInspect = { M.open, "Open structured CursorTab request inspector" },
    CursortabInspectClear = { M.clear, "Clear captured CursorTab request exchanges" },
    CursortabInspectProxyStatus = { M.proxy_status, "Show CursorTab inspect proxy status" },
    CursortabInspectProxyRestart = { M.restart_proxy, "Restart CursorTab inspect proxy" },
  }
  for name, command in pairs(commands) do
    pcall(vim.api.nvim_del_user_command, name)
    vim.api.nvim_create_user_command(name, command[1], { desc = command[2] })
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  local state_dir = vim.fn.expand(config.state_dir)
  vim.fn.mkdir(state_dir, "p")
  pcall(vim.uv.fs_chmod, state_dir, 448)
  setup_highlights()
  if not setup_done then
    create_commands()
    setup_done = true
  end
  if ensure_proxy_sync() then
    return M.provider_url()
  end
  return config.upstream_base .. "/beta"
end

return M
