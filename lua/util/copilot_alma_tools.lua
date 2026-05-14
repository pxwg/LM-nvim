local M = {}

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

function M.copilot_functions()
  return {
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
        if not should_disclose_workspace() then
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
