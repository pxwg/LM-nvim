local M = {}
vim.api.nvim_set_hl(0, "StatusLineFile", { fg = "#61afef", bold = true })
vim.api.nvim_set_hl(0, "StatusLineModified", { fg = "#e06c75", bold = true })
vim.api.nvim_set_hl(0, "StatusLineLang", { fg = "#98c379" })
vim.api.nvim_set_hl(0, "StatusLineBattery", { fg = "#d19a66" })
vim.api.nvim_set_hl(0, "StatusLineGit", { fg = "#eba0ac" })

local trouble = require("trouble")
local symbols = trouble.statusline({
  mode = "symbols",
  groups = {},
  title = false,
  filter = { range = true },
  format = "{kind_icon}{symbol.name:Normal}",
  hl_group = "StatusLineLang",
})

-- Cache for expensive operations
M.cache = {
  branch = "",
  branch_time = 0,
  battery_icon = "",
  battery_time = 0,
}

local function get_git_branch()
  local git_dir = vim.fn.finddir(".git", vim.fn.expand("%:p:h") .. ";")
  if git_dir == "" then
    return ""
  end

  -- Try to get from git HEAD file first (reduces shell execution)
  local head_file = git_dir .. "/HEAD"
  if vim.fn.filereadable(head_file) == 1 then
    local head_content = vim.fn.readfile(head_file)[1] or ""
    local branch_match = head_content:match("ref: refs/heads/(.+)")
    if branch_match then
      return branch_match
    end
  end

  -- Fall back to git command if needed
  local output = vim.fn.system("git -C " .. vim.fn.shellescape(vim.fn.expand("%:p:h")) .. " branch --show-current")
  if vim.v.shell_error ~= 0 then
    return ""
  end
  return vim.fn.trim(output)
end

local branch = get_git_branch()
vim.api.nvim_set_hl(0, "Statusline", { fg = "", bg = "" })

local home = _G.HOMEPARH
local filename = vim.fn.expand("%:f"):gsub(home, "")
vim.o.statusline = table.concat({
  -- "%#StatusLineFile#" .. filename, -- 文件名
  "%#StatusLineModified#%m", -- 修改标志
  "%=",
  symbols.get(),
  "%=",
  "%#StatusLineGit#" .. get_git_branch() .. " ",
  "%#StatusLineLang#[" .. "en" .. "] ",
  "%#StatusLineBattery#" .. require("util.battery").get_battery_icon() .. " ",
  "%#Statusline#",
})

function M.update_hl()
  filename = vim.fn.expand("%:f"):gsub(home, "")
  vim.api.nvim_set_hl(0, "Statusline", { fg = "", bg = "" })
  vim.o.statusline = table.concat({
    -- "%#StatusLineFile#" .. filename, -- 文件名
    "%#StatusLineModified#%m", -- 修改标志
    "%=",
    symbols.get(),
    "%=",
    "%#StatusLineGit#" .. get_git_branch() .. " ",
    "%#StatusLineLang#" .. "[" .. require("util.rime_ls").rime_toggle_word() .. "] ",
    "%#StatusLineBattery#" .. M.cache.battery_icon .. " ",
    "%#Statusline#", -- Reset highlight at the end
  })
  require("util.rime_ls").change_cursor_color()
end

return M
