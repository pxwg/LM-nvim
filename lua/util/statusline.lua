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

vim.o.statusline = table.concat({
  "%#StatusLineFile#%f", -- 文件名
  "%#StatusLineModified#%m", -- 修改标志
  -- "%=%{%v:lua.require'util.current_function'.get_current_function()%}%=",
  "%=",
  symbols.get(),
  "%=",
  "%#StatusLineLang#[" .. "en" .. "] ",
  "%#StatusLineBattery#" .. require("util.battery").get_battery_icon() .. " ",
  "%#Normal#",
})

function M.update_hl()
  vim.o.statusline = table.concat({
    "%#StatusLineFile#%f", -- 文件名
    "%#StatusLineModified#%m", -- 修改标志
    -- "%=%{%v:lua.require'util.current_function'.get_current_function()%}%=",
    "%=",
    symbols.get(),
    "%=",
    -- "%#StatusLineLang#".. require("cn)
    "%#StatusLineLang#"
      .. "["
      .. require("util.rime_ls").rime_toggle_word()
      .. "] ",
    "%#StatusLineBattery#" .. require("util.battery").get_battery_icon() .. " ",
    "%#Normal#", -- Reset highlight at the end(
  })
  require("util.rime_ls").change_cursor_color()
end
return M
