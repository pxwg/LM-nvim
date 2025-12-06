local M = {}

local last_file_dir = ""
local last_git_dir = ""

local function cwd(ignore_home)
  local file_dir = vim.fn.expand("%:p:h")
  local git_dir = vim.fn.system("git -C " .. file_dir .. " rev-parse --show-toplevel")

  if vim.bo.filetype == "neo-tree" or vim.bo.filetype == "copilot-chat" then
    if last_git_dir then
      return last_git_dir
    else
      return last_file_dir
    end
  end

  if vim.v.shell_error == 0 then
    local git_root = vim.fn.trim(git_dir)
    if git_root == vim.fn.expand("$HOME") then
      last_file_dir = file_dir
      return last_file_dir
    end
    last_git_dir = git_root
    return last_git_dir
  else
    last_file_dir = file_dir
    return last_file_dir
  end
end

local function get_cwd(fname)
  local file_path = vim.fn.expand(fname)
  local file_dir = vim.fn.fnamemodify(file_path, ":p:h")
  local git_cmd = "git -C " .. vim.fn.shellescape(file_dir) .. " rev-parse --show-toplevel"
  local git_dir = vim.fn.system(git_cmd)

  if vim.v.shell_error == 0 then
    local git_root = vim.fn.trim(git_dir)
    local home_dir = vim.fn.expand("$HOME")

    if git_root == home_dir then
      last_file_dir = file_dir
      return last_file_dir
    else
      last_git_dir = git_root
      return last_git_dir
    end
  else
    last_file_dir = file_dir
    return last_file_dir
  end
end

M.cwd = cwd
M.get_cwd = get_cwd

return M
