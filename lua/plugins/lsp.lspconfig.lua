require("util.lazyfile").lazy_file()
return {
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    priority = 1000,
    enabled = false,
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    version = "^1.0.0",
    cmd = "LspStart",
    event = "VeryLazy",
    dependencies = {
      -- Setup lsp installed in mason
      { "williamboman/mason-lspconfig.nvim", version = "^1.0.0" },
      -- Useful status updates for LSP
      { "j-hui/fidget.nvim", config = true, opts = { notification = { window = { winblend = 100 } } } },
    },
    opts = {
      ui = {
        windows = {
          default_options = {
            border = "rounded",
          },
        },
      },
    },
    config = function() end,
  },
}
