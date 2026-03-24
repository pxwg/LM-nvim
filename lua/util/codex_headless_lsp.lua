local M = {}

local function out(payload)
  io.stdout:write(vim.json.encode(payload) .. "\n")
  io.stdout:flush()
end

local function fail(message, extra)
  local payload = vim.tbl_extend("force", {
    ok = false,
    error = message,
  }, extra or {})
  out(payload)
  return payload
end

local function supports_method(client, method, bufnr)
  if not client then
    return false
  end
  return client:supports_method(method, { bufnr = bufnr })
end

local function normalize_location(item)
  if item.uri and item.range then
    return {
      path = vim.uri_to_fname(item.uri),
      uri = item.uri,
      range = item.range,
    }
  end

  if item.targetUri and item.targetSelectionRange then
    return {
      path = vim.uri_to_fname(item.targetUri),
      uri = item.targetUri,
      range = item.targetSelectionRange,
      targetRange = item.targetRange,
    }
  end

  return item
end

local function normalize_locations(result)
  if not result then
    return {}
  end

  if result.uri or result.targetUri then
    return { normalize_location(result) }
  end

  if vim.islist(result) then
    local items = {}
    for _, item in ipairs(result) do
      table.insert(items, normalize_location(item))
    end
    return items
  end

  return { result }
end

local function normalize_hover(result)
  if not result then
    return nil
  end

  local contents = result.contents
  if type(contents) == "string" then
    return { kind = "plaintext", value = contents }
  end

  if type(contents) == "table" and contents.kind and contents.value then
    return contents
  end

  if vim.islist(contents) then
    local chunks = {}
    for _, item in ipairs(contents) do
      if type(item) == "string" then
        table.insert(chunks, item)
      elseif type(item) == "table" and item.value then
        table.insert(chunks, item.value)
      end
    end
    return { kind = "markdown", value = table.concat(chunks, "\n") }
  end

  return { kind = "plaintext", value = vim.inspect(result) }
end

local function read_file_lines(file)
  return vim.fn.readfile(file)
end

local function build_match_item(file, lines, line_idx0, start_col0, end_col0, query)
  local line = lines[line_idx0 + 1] or ""
  local context_start = math.max(1, line_idx0)
  local context_end = math.min(#lines, line_idx0 + 3)
  local context = {}

  for i = context_start, context_end do
    table.insert(context, {
      line_1based = i,
      text = lines[i],
    })
  end

  return {
    file = file,
    query = query,
    match = line:sub(start_col0 + 1, end_col0),
    line_text = line,
    editor_position = {
      line = line_idx0 + 1,
      col = start_col0 + 1,
      end_col = end_col0,
    },
    lsp_position = {
      line = line_idx0,
      character = start_col0,
      end_character = end_col0,
    },
    context = context,
  }
end

local function find_string_matches(file, query)
  local lines = read_file_lines(file)
  local matches = {}

  for line_idx0, line in ipairs(lines) do
    local search_from = 1
    while true do
      local start_1based, end_1based = line:find(query, search_from, true)
      if not start_1based then
        break
      end

      local start_col0 = start_1based - 1
      local end_col0_exclusive = end_1based
      table.insert(matches, build_match_item(file, lines, line_idx0 - 1, start_col0, end_col0_exclusive, query))
      search_from = end_1based + 1
    end
  end

  return matches
end

local function candidate_columns(match)
  local start_col1 = match.editor_position.col
  local end_col1 = math.max(start_col1, match.editor_position.end_col)
  local cols = {}
  local seen = {}

  local function push(col)
    if col >= start_col1 and col <= end_col1 and not seen[col] then
      seen[col] = true
      table.insert(cols, col)
    end
  end

  push(start_col1)
  push(start_col1 + 1)
  push(start_col1 + 2)
  push(math.floor((start_col1 + end_col1) / 2))
  push(end_col1 - 1)
  push(end_col1)

  for col = start_col1, end_col1 do
    push(col)
  end

  return cols
end

local function config_names_for_filetype(filetype, wanted_client)
  local names = {}
  local seen = {}
  local files = vim.api.nvim_get_runtime_file("lsp/*.lua", true)

  for _, path in ipairs(files) do
    local name = vim.fn.fnamemodify(path, ":t:r")
    if not seen[name] then
      seen[name] = true
      if not wanted_client or name == wanted_client then
        local ok, config = pcall(function()
          return vim.lsp.config[name]
        end)
        if ok and config then
          local filetypes = config.filetypes
          if type(filetypes) == "table" then
            for _, ft in ipairs(filetypes) do
              if ft == filetype then
                table.insert(names, name)
                break
              end
            end
          end
        end
      end
    end
  end

  return names
end

local function start_configs_for_buffer(bufnr, wanted_client)
  local filetype = vim.bo[bufnr].filetype
  if not filetype or filetype == "" then
    return {}
  end

  local names = config_names_for_filetype(filetype, wanted_client)
  for _, name in ipairs(names) do
    local ok, config = pcall(function()
      return vim.lsp.config[name]
    end)
    if ok and config then
      vim.lsp.start(config, { bufnr = bufnr })
    end
  end
  return names
end

local function wait_for_clients(bufnr, method, timeout_ms, wanted_client)
  local matched = {}
  local ok = vim.wait(timeout_ms, function()
    matched = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      if (not wanted_client or client.name == wanted_client) and supports_method(client, method, bufnr) then
        table.insert(matched, client)
      end
    end
    return #matched > 0
  end, 50)

  return ok, matched
end

local function wait_for_any_client(bufnr, timeout_ms, wanted_client)
  local matched = {}
  local ok = vim.wait(timeout_ms, function()
    matched = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      if not wanted_client or client.name == wanted_client then
        table.insert(matched, client)
      end
    end
    return #matched > 0
  end, 50)

  return ok, matched
end

local function make_params(action, bufnr, client)
  if action == "references" then
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding or "utf-16")
    params.context = { includeDeclaration = true }
    return params
  end

  if action == "definition" then
    return vim.lsp.util.make_position_params(0, client.offset_encoding or "utf-16")
  end

  if action == "hover" then
    return vim.lsp.util.make_position_params(0, client.offset_encoding or "utf-16")
  end

  return nil
end

local function collect_request(action, method, bufnr, clients, timeout_ms)
  local pending = 0
  local responses = {}

  for _, client in ipairs(clients) do
    pending = pending + 1
    local params = make_params(action, bufnr, client)
    client:request(method, params, function(err, result)
      local entry = {
        client = client.name,
      }

      if err then
        entry.error = err.message or vim.inspect(err)
      elseif action == "hover" then
        entry.item = normalize_hover(result)
      else
        entry.items = normalize_locations(result)
      end

      table.insert(responses, entry)
      pending = pending - 1
    end, bufnr)
  end

  local completed = vim.wait(timeout_ms, function()
    return pending == 0
  end, 50)

  return completed, responses, pending
end

local function responses_ready(action, responses)
  if #responses == 0 then
    return false
  end

  for _, response in ipairs(responses) do
    if response.error then
      return true
    end
    if action == "hover" then
      if response.item ~= nil then
        return true
      end
    else
      if response.items and #response.items > 0 then
        return true
      end
    end
  end

  return false
end

local function collect_request_until_ready(action, method, bufnr, clients, total_timeout_ms, poll_ms)
  local started = vim.loop.hrtime()
  local deadline = started + total_timeout_ms * 1000000
  local last_completed = false
  local last_responses = {}
  local last_pending = 0
  local settled = false

  while vim.loop.hrtime() < deadline do
    local remaining_ms = math.max(100, math.floor((deadline - vim.loop.hrtime()) / 1000000))
    last_completed, last_responses, last_pending = collect_request(action, method, bufnr, clients, remaining_ms)

    if responses_ready(action, last_responses) then
      settled = true
      break
    end

    if vim.loop.hrtime() >= deadline then
      break
    end

    vim.wait(poll_ms)
  end

  return settled, last_completed, last_responses, last_pending
end

local function collect_diagnostics(bufnr, timeout_ms, wanted_client)
  local started = vim.loop.hrtime()
  local deadline = started + timeout_ms * 1000000
  local last_count = -1
  local stable_since = nil

  while vim.loop.hrtime() < deadline do
    local diagnostics = vim.diagnostic.get(bufnr)
    local filtered = {}
    for _, item in ipairs(diagnostics) do
      if not wanted_client or item.source == wanted_client then
        table.insert(filtered, item)
      end
    end

    if #filtered ~= last_count then
      last_count = #filtered
      stable_since = vim.loop.hrtime()
    elseif stable_since and (vim.loop.hrtime() - stable_since) > 250 * 1000000 then
      local items = {}
      for _, item in ipairs(filtered) do
        table.insert(items, {
          source = item.source,
          code = item.code,
          severity = item.severity,
          message = item.message,
          range = item.range,
        })
      end
      return true, items
    end

    vim.wait(50)
  end

  local items = {}
  for _, item in ipairs(vim.diagnostic.get(bufnr)) do
    if not wanted_client or item.source == wanted_client then
      table.insert(items, {
        source = item.source,
        code = item.code,
        severity = item.severity,
        message = item.message,
        range = item.range,
      })
    end
  end
  return false, items
end

local methods = {
  definition = "textDocument/definition",
  references = "textDocument/references",
  hover = "textDocument/hover",
  diagnostics = nil,
  locate = nil,
  ["locate-definition"] = "textDocument/definition",
  ["locate-references"] = "textDocument/references",
}

local locate_actions = {
  locate = true,
  ["locate-definition"] = true,
  ["locate-references"] = true,
}

local function execute_lsp_query(opts)
  local action = opts.action
  local file = opts.file and vim.fn.fnamemodify(opts.file, ":p") or nil
  local line = math.max(1, tonumber(opts.line) or 1)
  local col = math.max(1, tonumber(opts.col) or 1)
  local timeout_ms = tonumber(opts.timeout_ms) or 4000
  local settle_ms = tonumber(opts.settle_ms) or 500
  local poll_ms = tonumber(opts.poll_ms) or 250
  local wanted_client = opts.client and opts.client ~= "" and opts.client or nil

  if not file or vim.fn.filereadable(file) == 0 then
    return fail("file not found", { file = file })
  end

  vim.cmd("silent edit " .. vim.fn.fnameescape(file))
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_cursor(0, { line, col - 1 })
  local enabled_configs = start_configs_for_buffer(bufnr, wanted_client)

  if action == "diagnostics" then
    local ok, clients = wait_for_any_client(bufnr, timeout_ms, wanted_client)
    if ok and settle_ms > 0 then
      vim.wait(settle_ms)
    end
    local settled, items = collect_diagnostics(bufnr, timeout_ms, wanted_client)
    local client_names = {}
    for _, client in ipairs(clients) do
      table.insert(client_names, client.name)
    end
    return {
      ok = ok,
      action = action,
      file = file,
      position = { line = line, col = col },
      enabled_configs = enabled_configs,
      clients = client_names,
      settled = settled,
      items = items,
    }
  end

  local method = methods[action]
  local ok, clients = wait_for_clients(bufnr, method, timeout_ms, wanted_client)
  if not ok then
    return fail("no LSP client attached for method", {
      action = action,
      file = file,
      method = method,
      client = wanted_client,
      enabled_configs = enabled_configs,
    })
  end

  if settle_ms > 0 then
    vim.wait(settle_ms)
  end

  local settled, completed, responses, pending =
    collect_request_until_ready(action, method, bufnr, clients, timeout_ms, poll_ms)
  return {
    ok = completed,
    settled = settled,
    action = action,
    file = file,
    position = { line = line, col = col },
    enabled_configs = enabled_configs,
    clients = vim.tbl_map(function(client)
      return client.name
    end, clients),
    pending = pending,
    responses = responses,
  }
end

function M.run(opts)
  local action = opts.action
  local file = opts.file and vim.fn.fnamemodify(opts.file, ":p") or nil
  local line = math.max(1, tonumber(opts.line) or 1)
  local col = math.max(1, tonumber(opts.col) or 1)
  local timeout_ms = tonumber(opts.timeout_ms) or 4000
  local settle_ms = tonumber(opts.settle_ms) or 500
  local poll_ms = tonumber(opts.poll_ms) or 250
  local wanted_client = opts.client and opts.client ~= "" and opts.client or nil
  local query = opts.query

  if not methods[action] and action ~= "diagnostics" and not locate_actions[action] then
    return fail("unsupported action", { action = action })
  end

  if not file or vim.fn.filereadable(file) == 0 then
    return fail("file not found", { file = file })
  end

  if
    (action == "locate" or action == "locate-definition" or action == "locate-references")
    and (not query or query == "")
  then
    return fail("query is required for locate actions", { action = action })
  end

  if action == "locate" then
    local matches = find_string_matches(file, query)
    local payload = {
      ok = true,
      action = action,
      file = file,
      query = query,
      count = #matches,
      matches = matches,
      indexing = {
        editor_positions_are_1_based = true,
        lsp_positions_are_0_based = true,
      },
    }
    out(payload)
    return payload
  end

  if action == "locate-definition" or action == "locate-references" then
    local base_action = action == "locate-definition" and "definition" or "references"
    local matches = find_string_matches(file, query)
    local attempts = {}
    local aggregate = {}

    for _, match in ipairs(matches) do
      local columns = candidate_columns(match)
      local successful = nil

      for _, candidate_col in ipairs(columns) do
        local result = execute_lsp_query({
          action = base_action,
          file = file,
          line = match.editor_position.line,
          col = candidate_col,
          client = wanted_client,
          timeout_ms = timeout_ms,
          settle_ms = settle_ms,
          poll_ms = poll_ms,
        })

        local attempt = {
          match = match,
          tried_col_1based = candidate_col,
          result = result,
        }
        table.insert(attempts, attempt)

        local has_items = false
        if result and result.responses then
          for _, response in ipairs(result.responses) do
            if response.items and #response.items > 0 then
              has_items = true
              for _, item in ipairs(response.items) do
                table.insert(aggregate, item)
              end
            end
          end
        end

        if has_items then
          successful = attempt
          break
        end
      end

      if successful then
        -- Keep searching other matches so multiple occurrences can still surface.
      end
    end

    local payload = {
      ok = true,
      action = action,
      delegated_action = base_action,
      file = file,
      query = query,
      count = #matches,
      matches = matches,
      attempts = attempts,
      items = aggregate,
      indexing = {
        editor_positions_are_1_based = true,
        lsp_positions_are_0_based = true,
      },
    }
    out(payload)
    return payload
  end

  local payload = execute_lsp_query({
    action = action,
    file = file,
    line = line,
    col = col,
    client = wanted_client,
    timeout_ms = timeout_ms,
    settle_ms = settle_ms,
    poll_ms = poll_ms,
  })
  out(payload)
  return payload
end

function M.run_from_argv(argv)
  local args = argv or vim.fn.argv()
  if #args < 2 then
    fail("usage: <action> <file> [line] [col] [client] [timeout_ms] [query]", { argv = args })
    vim.cmd("qa!")
    return
  end

  local action = args[1]
  local file = args[2]
  local line = args[3]
  local col = args[4]
  local client = args[5]
  local timeout_ms = args[6]
  local query = args[7]

  if action == "locate" or action == "locate-definition" or action == "locate-references" then
    query = args[3]
    line = nil
    col = nil
    client = args[4]
    timeout_ms = args[5]
  end

  M.run({
    action = action,
    file = file,
    line = line,
    col = col,
    client = client,
    timeout_ms = timeout_ms,
    query = query,
  })
  vim.cmd("qa!")
end

function M.command(fargs)
  M.run_from_argv(fargs)
end

return M
