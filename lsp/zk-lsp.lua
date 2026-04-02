return {
  name = "zk-lsp",
  cmd = { "zk-lsp" },
  root_dir = "~/wiki",
  filetypes = { "typst" },
  offset_encoding = "utf-16",
  on_attach = function(client, bufnr)
    local buf_path = vim.api.nvim_buf_get_name(bufnr)
    local wiki_root = vim.fn.expand("~/wiki")
    if not vim.startswith(buf_path, wiki_root) then
      vim.schedule(function()
        vim.lsp.stop_client(client.id)
      end)
    end
  end,
}
