vim.o.statusline = table.concat({
  "%f", -- 文件名
  "%m", -- 修改标志
  -- "%=%{%v:lua.require'util.current_function'.get_current_function()%}%=",
  "%=",
  "[" .. "en" .. "] ",
  require("util.battery").get_battery_icon() .. " ",
})
