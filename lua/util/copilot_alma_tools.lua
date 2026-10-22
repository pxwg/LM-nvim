local M = {}

local ALMA_TIMEOUT_MS = 15000
local ALMA_OUTPUT_MAX_BYTES = 80000
local ALMA_STDERR_MAX_BYTES = 12000

local function truncate_text(text, max_bytes, label)
  text = tostring(text or "")
  if #text <= max_bytes then
    return text
  end

  return text:sub(1, max_bytes)
    .. string.format(
      "\n\n[CopilotChat alma guard: %s truncated after %d bytes; original output exceeded the limit.]",
      label or "output",
      max_bytes
    )
end

local function bounded_alma(args, opts)
  if vim.fn.executable("alma") ~= 1 then
    error("alma executable not found")
  end

  opts = opts or {}
  local timeout_ms = opts.timeout_ms or ALMA_TIMEOUT_MS
  local max_stdout = opts.max_stdout_bytes or ALMA_OUTPUT_MAX_BYTES
  local max_stderr = opts.max_stderr_bytes or ALMA_STDERR_MAX_BYTES
  local cmd = vim.list_extend({ "alma" }, args)
  local result = vim.system(cmd, { text = true }):wait(timeout_ms) or {}

  local stdout = truncate_text(result.stdout or "", max_stdout, "stdout")
  local stderr = truncate_text(result.stderr or "", max_stderr, "stderr")
  local guard = {}
  if result.signal and result.signal ~= 0 then
    table.insert(guard, string.format("alma command timed out or was terminated after %dms", timeout_ms))
  end
  if result.code and result.code ~= 0 then
    table.insert(guard, string.format("alma exited with code %d", result.code))
  end

  if stderr ~= "" then
    stdout = stdout .. (stdout ~= "" and "\n\n" or "") .. "[stderr]\n" .. stderr
  end
  if #guard > 0 then
    stdout = stdout
      .. (stdout ~= "" and "\n\n" or "")
      .. "[CopilotChat alma guard: "
      .. table.concat(guard, "; ")
      .. ".]"
  end

  return stdout ~= "" and stdout or "(no output)"
end

local function require_string(input, key)
  local value = input and input[key] or nil
  if type(value) ~= "string" or vim.trim(value) == "" then
    error("Missing required string field: " .. key)
  end
  return vim.trim(value)
end

local function optional_positive_integer(input, key, default, max)
  local value = input and input[key] or nil
  if value == nil or value == "" then
    return default
  end
  value = tonumber(value)
  if not value or value < 1 then
    error("Expected positive integer field: " .. key)
  end
  value = math.floor(value)
  if max then
    value = math.min(value, max)
  end
  return value
end

local function bool_flag(args, input, key, flag)
  if input and input[key] == true then
    table.insert(args, flag)
  end
end

local function memory_args(input)
  local action = require_string(input, "action")
  local args = { "memory", action }

  if action == "list" or action == "stats" then
    return args
  elseif action == "search" then
    table.insert(args, require_string(input, "query"))
    return args
  elseif action == "add" then
    table.insert(args, require_string(input, "content"))
    return args
  elseif action == "delete" then
    table.insert(args, require_string(input, "id"))
    return args
  end

  error("Unsupported alma memory action: " .. action)
end

local function activity_args(input)
  local action = require_string(input, "action")
  local args = { "activity", action }

  if action == "status" or action == "start" or action == "stop" then
    return args
  elseif action == "config" then
    local mode = input and input.mode or nil
    if type(mode) ~= "string" or mode == "" then
      return args
    end
    table.insert(args, mode)
    if mode == "set" then
      table.insert(args, require_string(input, "key"))
      table.insert(args, require_string(input, "value"))
    elseif mode ~= "get" then
      error("Unsupported alma activity config mode: " .. mode)
    end
    return args
  elseif action == "sessions" then
    table.insert(args, tostring(optional_positive_integer(input, "limit", 10, 100)))
    return args
  elseif action == "show" or action == "analyze" then
    table.insert(args, require_string(input, "session_id"))
    return args
  elseif action == "search" then
    local mode = input and input.mode or "keyword"
    if mode == "semantic" then
      table.insert(args, "semantic")
    elseif mode ~= "keyword" then
      error("Unsupported alma activity search mode: " .. tostring(mode))
    end
    table.insert(args, require_string(input, "query"))
    return args
  elseif action == "summary" then
    local period = input and input.period or "daily"
    if period ~= "daily" and period ~= "weekly" then
      error("alma activity summary period must be daily or weekly")
    end
    table.insert(args, period)
    if type(input.date) == "string" and input.date ~= "" then
      table.insert(args, input.date)
    end
    bool_flag(args, input, "narrative", "--narrative")
    return args
  elseif action == "digest" then
    bool_flag(args, input, "narrative", "--narrative")
    local lookback = optional_positive_integer(input, "lookback_minutes", nil, 24 * 60)
    if lookback then
      table.insert(args, "--lookback")
      table.insert(args, tostring(lookback))
    end
    local max_analyzed = optional_positive_integer(input, "max_analyzed", nil, 50)
    if max_analyzed then
      table.insert(args, "--max-analyzed")
      table.insert(args, tostring(max_analyzed))
    end
    return args
  elseif action == "report" then
    if type(input.date) == "string" and input.date ~= "" then
      table.insert(args, input.date)
    end
    bool_flag(args, input, "force", "--force")
    bool_flag(args, input, "skeleton", "--skeleton")
    bool_flag(args, input, "json", "--json")
    return args
  end

  error("Unsupported alma activity action: " .. action)
end

local function alma_result(name, args, output)
  return {
    {
      uri = "alma://" .. name,
      name = "Alma " .. name,
      mimetype = "text/plain",
      data = "$ alma " .. table.concat(args, " ") .. "\n\n" .. output,
    },
  }
end

function M.copilot_functions()
  return {
    alma_memory = {
      group = "alma",
      uri = "alma-memory://{action}",
      description = "Use Alma CLI global memory. Actions: list, stats, search(query), add(content), delete(id). Use add only for durable user preferences, long-term facts, or reusable project knowledge.",
      schema = {
        type = "object",
        required = { "action" },
        properties = {
          action = {
            type = "string",
            enum = { "list", "stats", "search", "add", "delete" },
            description = "Memory action to run.",
          },
          query = {
            type = "string",
            description = "Search query for action=search.",
          },
          content = {
            type = "string",
            description = "Durable memory content for action=add.",
          },
          id = {
            type = "string",
            description = "Memory id for action=delete.",
          },
        },
      },
      resolve = function(input)
        local args = memory_args(input)
        return alma_result("memory/" .. args[2], args, bounded_alma(args))
      end,
    },
    alma_activity = {
      group = "alma",
      uri = "alma-activity://{action}",
      description = "Use Alma CLI activity recorder. Actions: status, start, stop, config, sessions, show, search, summary, digest, report, analyze. Prefer digest/report/search for recent user context and evidence.",
      schema = {
        type = "object",
        required = { "action" },
        properties = {
          action = {
            type = "string",
            enum = {
              "status",
              "start",
              "stop",
              "config",
              "sessions",
              "show",
              "search",
              "summary",
              "digest",
              "report",
              "analyze",
            },
            description = "Activity recorder action to run.",
          },
          mode = {
            type = "string",
            description = "For action=search: keyword or semantic. For action=config: get or set.",
          },
          query = {
            type = "string",
            description = "Search query for action=search.",
          },
          session_id = {
            type = "string",
            description = "Session id for action=show or action=analyze.",
          },
          limit = {
            type = "number",
            description = "Session count for action=sessions.",
          },
          period = {
            type = "string",
            enum = { "daily", "weekly" },
            description = "Summary period for action=summary.",
          },
          date = {
            type = "string",
            description = "Date selector for summary/report, for example today, yesterday, or YYYY-MM-DD.",
          },
          lookback_minutes = {
            type = "number",
            description = "Lookback window for action=digest.",
          },
          max_analyzed = {
            type = "number",
            description = "Maximum analyzed sessions for action=digest.",
          },
          narrative = {
            type = "boolean",
            description = "Pass --narrative where supported.",
          },
          force = {
            type = "boolean",
            description = "Pass --force for action=report.",
          },
          skeleton = {
            type = "boolean",
            description = "Pass --skeleton for action=report.",
          },
          json = {
            type = "boolean",
            description = "Pass --json for action=report.",
          },
          key = {
            type = "string",
            description = "Config key for action=config mode=set.",
          },
          value = {
            type = "string",
            description = "Config value for action=config mode=set.",
          },
        },
      },
      resolve = function(input)
        local args = activity_args(input)
        return alma_result(
          "activity/" .. args[2],
          args,
          bounded_alma(args, {
            timeout_ms = input and input.action == "report" and 30000 or ALMA_TIMEOUT_MS,
            max_stdout_bytes = input and input.action == "show" and 120000 or ALMA_OUTPUT_MAX_BYTES,
          })
        )
      end,
    },
  }
end

return M
