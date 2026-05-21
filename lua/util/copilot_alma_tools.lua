local M = {}

local ALMA_TIMEOUT_MS = 15000
local ALMA_OUTPUT_MAX_BYTES = 80000
local ALMA_STDERR_MAX_BYTES = 12000

local function normalize_path(path)
  if type(path) ~= "string" or path == "" or path:match("^%w+://") then
    return nil
  end
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function path_is_under(root, path)
  root = normalize_path(root)
  path = normalize_path(path)
  if not root or not path then
    return false
  end

  root = root:gsub("/+$", "")
  path = path:gsub("/+$", "")
  return path == root or path:sub(1, #root + 1) == root .. "/"
end

local function wiki_root()
  return vim.fs.normalize(vim.g.zk_alma_wiki_root or ((vim.uv.os_homedir() or vim.fn.expand("~")) .. "/wiki"))
end

local function should_disclose_workspace()
  local root = wiki_root()
  if path_is_under(root, vim.fn.getcwd()) then
    return true
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  return path_is_under(root, bufname)
end

local function current_registered_workspace()
  local ok, blackboard = pcall(require, "util.alma_zk_blackboard")
  if not ok or type(blackboard.status) ~= "function" then
    return nil
  end

  local ok_status, status = pcall(blackboard.status)
  if not ok_status or type(status) ~= "table" then
    return nil
  end

  local workspace_id = status.current_workspace_id
  local workspace = workspace_id and status.workspaces and status.workspaces[workspace_id] or nil
  if type(workspace_id) ~= "string" or workspace_id == "" or type(workspace) ~= "table" then
    return nil
  end

  return workspace, status
end

local function current_buffer_facts()
  local bufnr = vim.api.nvim_get_current_buf()
  return {
    bufnr = bufnr,
    name = vim.api.nvim_buf_get_name(bufnr),
    filetype = vim.bo[bufnr].filetype,
    modified = vim.bo[bufnr].modified,
  }
end

local function workspace_lines()
  local ok, blackboard = pcall(require, "util.alma_zk_blackboard")
  if not ok or type(blackboard.status) ~= "function" then
    return { "alma zk blackboard status: unavailable" }
  end

  local ok_status, status = pcall(blackboard.status)
  if not ok_status or type(status) ~= "table" then
    return { "alma zk blackboard status: unavailable" }
  end

  local lines = {}
  if status.current_workspace_id then
    table.insert(lines, "current workspace id: " .. status.current_workspace_id)
  end

  local workspaces = status.workspaces or {}
  local workspace_ids = vim.tbl_keys(workspaces)
  table.sort(workspace_ids)
  if #workspace_ids == 0 then
    table.insert(lines, "registered workspaces: none")
  else
    table.insert(lines, "registered workspaces:")
    for _, id in ipairs(workspace_ids) do
      local workspace = workspaces[id] or {}
      table.insert(
        lines,
        string.format("- %s root=%s note_dir=%s", id, workspace.root or "?", workspace.note_dir or "?")
      )
    end
  end

  local bindings = status.thread_bindings or {}
  local thread_ids = vim.tbl_keys(bindings)
  table.sort(thread_ids)
  if #thread_ids > 0 then
    table.insert(lines, "bound alma threads:")
    for _, thread_id in ipairs(thread_ids) do
      local binding = bindings[thread_id] or {}
      table.insert(lines, string.format("- %s -> %s", thread_id, binding.workspace_id or "?"))
    end
  end

  return lines
end

local function visible_workspace_buffers()
  local ok, blackboard = pcall(require, "util.alma_zk_blackboard")
  if not ok or type(blackboard.status) ~= "function" then
    return {}
  end

  local ok_status, status = pcall(blackboard.status)
  if not ok_status or type(status) ~= "table" then
    return {}
  end

  local current_workspace_id = status.current_workspace_id
  local current_workspace = current_workspace_id and status.workspaces and status.workspaces[current_workspace_id]
    or nil
  local root = current_workspace and current_workspace.root or nil
  if type(root) ~= "string" or root == "" then
    return {}
  end

  local out = {}
  root = vim.fs.normalize(root):gsub("/+$", "")
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local bufnr = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
        local name = vim.api.nvim_buf_get_name(bufnr)
        local normalized = name ~= "" and vim.fs.normalize(name) or ""
        if normalized == root or normalized:sub(1, #root + 1) == root .. "/" then
          table.insert(out, string.format("- bufnr=%d path=%s ft=%s", bufnr, normalized, vim.bo[bufnr].filetype))
        end
      end
    end
  end
  table.sort(out)
  return out
end

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
    alma_zk_workspace = {
      group = "alma",
      uri = "alma-zk-workspace://current",
      description = "Instructions for writing CopilotChat output into the linked alma.nvim ZK workspace buffers.",
      schema = {
        type = "object",
        properties = {},
        required = {},
      },
      resolve = function()
        local registered_workspace = current_registered_workspace()
        if not registered_workspace or not should_disclose_workspace() then
          return {}
        end

        local buf = current_buffer_facts()
        local lines = {
          "# Alma ZK Workspace Tool",
          "",
          "Use this when the user asks for ZK workspace, note, link, or alma.nvim blackboard work.",
          "",
          "Operating contract:",
          "- Put generated or revised content directly into the appropriate workspace buffer whenever possible.",
          "- Prefer existing visible workspace buffers. If none is suitable, open or create a file under the active workspace root or note_dir.",
          "- Keep the chat response short: summarize what changed and name the buffer or file.",
          "- Do not leave long drafts, note bodies, or patch-sized content only in chat when a workspace buffer can hold it.",
          "- Use the available Neovim interaction tools to inspect buffers, open files, and write text.",
          "",
          "Current buffer:",
          string.format(
            "- bufnr=%d path=%s ft=%s modified=%s",
            buf.bufnr,
            buf.name ~= "" and buf.name or "[unnamed]",
            buf.filetype,
            tostring(buf.modified)
          ),
          "",
          "Workspace state:",
        }

        vim.list_extend(lines, workspace_lines())

        local visible = visible_workspace_buffers()
        table.insert(lines, "")
        table.insert(lines, "Visible workspace buffers:")
        if #visible == 0 then
          table.insert(lines, "- none detected")
        else
          vim.list_extend(lines, visible)
        end

        return {
          {
            uri = "alma://zk-workspace-instructions",
            name = "Alma ZK Workspace Instructions",
            mimetype = "text/markdown",
            data = table.concat(lines, "\n"),
          },
        }
      end,
    },
  }
end

return M
