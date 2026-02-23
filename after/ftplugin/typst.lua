-- 针对 Typst 文件的快捷配置
-- 如果已经有基础 runtime path, 确保 lua/typst_build.lua 在 runtimepath 下

-- 可选：buffer 本地编译输出目录/文件
-- vim.b.typst_output = "out.pdf"

local ok, tb = pcall(require, "util.typst_build")
if not ok then
  vim.notify("无法加载 typst_build.lua", vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command("TypstBuild", function(opts)
  tb.build_current({ out = vim.b.typst_output or "" })
end, {})

-- Treesitter folding: fold block_comment nodes (metadata block)
-- vim.schedule(function()
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt_local.foldlevel = 0
-- end)
