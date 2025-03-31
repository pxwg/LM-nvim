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

local function get_branch()
  local current_time = vim.loop.now()
  -- Update git branch at most every 5 seconds
  if current_time - M.cache.branch_time > 5000 then
    local branch =
      vim.fn.system("git -C " .. vim.fn.expand("%:p:h") .. " branch --show-current 2>/dev/null | tr -d '\n'")
    if vim.v.shell_error == 0 and branch ~= "" then
      M.cache.branch = " " .. branch
    else
      M.cache.branch = ""
    end
    M.cache.branch_time = current_time
  end
  return M.cache.branch
end

local Job = require("plenary.job")
local branch = ""
Job:new({
  command = "git",
  args = { "branch", "--show-current" },
  cwd = vim.fn.expand("%:p:h"),
  on_exit = function(j, _)
    branch = j:result()[1] or ""
  end,
}):sync()

vim.o.statusline = table.concat({
  "%#StatusLineFile#%f", -- 文件名
  "%#StatusLineModified#%m", -- 修改标志
  "%=",
  symbols.get(),
  "%=",
  "%#StatusLineGit#" .. branch .. " ",
  "%#StatusLineLang#[" .. "en" .. "] ",
  "%#StatusLineBattery#" .. require("util.battery").get_battery_icon() .. " ",
  "%#Normal#",
})

function M.update_hl()
  local current_time = vim.loop.now()
  -- Update battery info at most every 30 seconds
  if current_time - M.cache.battery_time > 30000 then
    M.cache.battery_icon = require("util.battery").get_battery_icon()
    M.cache.battery_time = current_time
  end
  local Job = require("plenary.job")
  local branch = ""
  Job:new({
    command = "git",
    args = { "branch", "--show-current" },
    cwd = vim.fn.expand("%:p:h"),
    on_exit = function(j, _)
      branch = j:result()[1] or ""
    end,
  }):sync()

  vim.o.statusline = table.concat({
    "%#StatusLineFile#%f", -- 文件名
    "%#StatusLineModified#%m", -- 修改标志
    "%=",
    symbols.get(),
    "%=",
    "%#StatusLineGit#" .. branch .. " ",
    "%#StatusLineLang#" .. "[" .. require("util.rime_ls").rime_toggle_word() .. "] ",
    "%#StatusLineBattery#" .. M.cache.battery_icon .. " ",
    "%#Normal#", -- Reset highlight at the end
  })
  require("util.rime_ls").change_cursor_color()
end
return M
