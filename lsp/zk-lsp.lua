local note_dir = vim.fs.normalize(vim.fn.expand("~/wiki/note"))
local wiki_root = vim.fs.normalize(vim.fn.expand("~/wiki"))

local function is_note_typst(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or vim.bo[bufnr].filetype ~= "typst" then
    return false
  end

  local path = vim.fs.normalize(name)
  return vim.startswith(path, note_dir .. "/") and path:sub(-4) == ".typ"
end

return {
  name = "zk-lsp",
  cmd = { "zk-lsp" },
  root_dir = function(bufnr, on_dir)
    if is_note_typst(bufnr) then
      on_dir(wiki_root)
    end
  end,
  filetypes = { "typst" },
  offset_encoding = "utf-16",
  on_attach = function(client, bufnr)
    if not is_note_typst(bufnr) then
      vim.lsp.buf_detach_client(bufnr, client.id)
    end
  end,
}
