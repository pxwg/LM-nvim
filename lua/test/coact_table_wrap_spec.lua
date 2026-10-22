-- Run: nvim --headless -u NONE -l lua/test/coact_table_wrap_spec.lua
local spec = dofile("lua/plugins/edit.markdown.table.wrap.nvim.lua")
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/markdown-table-wrap.nvim")
local table_wrap = require("markdown-table-wrap")
local rendered = {}
vim.api.nvim_create_autocmd("User", {
  pattern = "MarkdownTableWrapRendered",
  callback = function(event)
    rendered[event.data.source_bufnr] = (rendered[event.data.source_bufnr] or 0) + 1
  end,
})
table_wrap.setup(spec.opts)

for _, ft in ipairs({ "coact", "coact-history", "coact-input" }) do
  assert(vim.tbl_contains(spec.ft, ft), ft .. " must trigger lazy loading")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = ft
  local lines = {
    "Conversation",
    "| 项目 | 内容 |",
    "| --- | --- |",
    "| 表格 | 中文与 long wrapped cell content |",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = ft == "coact-input"
  vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
  assert(vim.wait(1500, function() return (rendered[buf] or 0) > 0 end), ft .. " must auto-render")
  assert(vim.api.nvim_get_current_buf() == buf, "must not replace the chat buffer")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), lines), "must not rewrite Source")
  assert(vim.bo[buf].modifiable == (ft == "coact-input"), "must preserve modifiable")
  assert(table_wrap.get_preview_mode(buf) == "inline")

  local count = rendered[buf]
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "| 新行 | streamed response |" })
  vim.bo[buf].modifiable = ft == "coact-input"
  vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
  assert(vim.wait(1500, function() return rendered[buf] > count end), ft .. " must refresh after streaming")
  vim.api.nvim_buf_delete(buf, { force = true })
end
print("coact_table_wrap_spec: 3 filetypes passed (auto-render, streaming, Source preservation)")
vim.cmd("qa!")
