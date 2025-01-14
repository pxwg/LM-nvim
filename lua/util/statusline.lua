vim.o.statusline = table.concat({
  "%f", -- 文件名
  "%m", -- 修改标志
  "%=",
  "[" .. "cn" .. "] ",
  require("util.battery").get_battery_icon() .. " ",
})
