vim.o.statusline = table.concat({
  "%f", -- 文件名
  "%m", -- 修改标志
  "%=",
  "[" .. "en" .. "] ",
  require("util.battery").get_battery_icon() .. " ",
})
