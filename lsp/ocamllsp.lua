return {
  name = "ocamllsp",
  -- Resolve the switch from the project root, even when Neovim starts elsewhere.
  cmd = function(dispatchers, config)
    return vim.lsp.rpc.start({ "opam", "exec", "--", "ocamllsp" }, dispatchers, {
      cwd = config.root_dir,
    })
  end,
  filetypes = { "ocaml", "ocaml.interface" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, {
      "dune-project",
      "dune-workspace",
      "_opam",
      "opam",
      function(name)
        return name:match("%.opam$") ~= nil
      end,
      ".git",
    })
    on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
  end,
}
