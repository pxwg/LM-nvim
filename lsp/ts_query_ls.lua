return {
  name = "ts_query_ls",
  cmd = { "ts_query_ls" },
  filetypes = { "scheme" },

  root_dir = vim.fs.root(0, { ".tsqueryrc.json", "queries" }),
  on_attach = function(_, buf)
    vim.bo[buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
  init_options = {
    parser_aliases = {
      ecma = "javascript",
    },
    language_retrieval_patterns = {
      "languages/src/([^/]+)/[^/]+\\.scm$",
    },
  },
}
