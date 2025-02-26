require("util.lazyfile").lazy_file()
return {
  "neovim/nvim-lspconfig",
  event = { "LazyFile" },
  cmd = "LspStart",
  dependencies = {
    -- Setup lsp installed in mason
    "williamboman/mason-lspconfig.nvim",
    -- Useful status updates for LSP
    { "j-hui/fidget.nvim", config = true },
  },
  config = function()
    local lspconfig = require("lspconfig")
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
    capabilities.general.positionEncodings = { "utf-8", "utf-16" }

    -- Load mason_lspconfig
    require("mason-lspconfig").setup_handlers({
      function(server_name)
        require("lspconfig")[server_name].setup({
          offset_encoding = "utf-8", -- wtf? if not set, it shows warning
          capabilities = capabilities,
          settings = {
            Lua = {
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
              },
              diagnostics = {
                globals = { "hs" },
              },
            },
          },
          -- 设置 root_dir 以确保正确的工作目录
          root_dir = function(fname)
            return lspconfig.util.root_pattern(".git")(fname) or vim.loop.os_homedir()
          end,
        })
      end,
    })
    require("lsp.rime_ls").setup_rime()

    lspconfig.texlab.setup({
      filetypes = { "tex", "bib" },
      -- offset_encoding = "utf-8", -- wtf? if not set, it shows warning
      capabilities = capabilities,
    })
  end,
}
