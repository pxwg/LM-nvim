local opts = {
  executable = "zk-lsp",
  wiki_root = vim.fs.normalize(vim.fn.expand("~/wiki")),
}

return {
  dir = vim.fn.expand("~/zk-lsp.nvim"),
  name = "zk-lsp.nvim",
  event = "VeryLazy",
  dependencies = {
    "folke/snacks.nvim",
  },
  build = function()
    require("zk_lsp").build(opts)
  end,
  config = function()
    require("zk_lsp").setup(opts)
  end,
}
