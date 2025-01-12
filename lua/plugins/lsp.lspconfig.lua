return {
  "neovim/nvim-lspconfig",
  event = "UIEnter",
  dependencies = {
    -- Setup lsp installed in mason
    "williamboman/mason-lspconfig.nvim",
    -- Useful status updates for LSP
    { "j-hui/fidget.nvim", config = true },
  },
  config = function()
    local lspconfig = require("lspconfig")
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    -- capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
    capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
    capabilities.general.positionEncodings = { "utf-8", "utf-16" }

    -- Load mason_lspconfig
    require("mason-lspconfig").setup_handlers({
      function(server_name)
        require("lspconfig")[server_name].setup({
          offset_encoding = "utf-8", -- wtf? if not set, it shows warning
          capabilities = capabilities,
          -- on_attach = on_attach,
        })
      end,
    })
    require("lsp.rime_ls").setup_rime()

    -- Add key mappings
  end,
}
