local M = {}

local last_file_dir = nil
local last_git_dir = nil

local function cwd()
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
    last_git_dir = vim.fn.trim(git_dir)
    print(last_git_dir)
    return last_git_dir
  else
    last_file_dir = file_dir
    print(last_file_dir)
    return last_file_dir
  end
end

M.cwd = cwd

return M
