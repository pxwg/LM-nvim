local M = {}

function M.setup_ts_query_lsp()
  vim.g.query_lint_on = {}

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*.scm",
    callback = function(ev)
      if vim.bo[ev.buf].buftype == "nofile" then
        return
      end
      vim.lsp.start({
        name = "ts_query_ls",
        cmd = { "ts_query_ls" },
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
      })
    end,
  })
end

return M
