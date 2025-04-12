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
    -- event = { "VeryLazy", "BufEnter", "BufReadPost", "BufWritePost", "BufNewFile" },
    event = { "LazyFile" },
    cmd = "LspStart",
    dependencies = {
      -- Setup lsp installed in mason
      "williamboman/mason-lspconfig.nvim",
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
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
      capabilities.general.positionEncodings = { "utf-8", "utf-16" }

      -- Load mason_lspconfig
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
            root_dir = function(fname)
              local dir = require("util.cwd_attach").get_cwd(fname)
              return dir
            end,
            settings = {
              Lua = {
                workspace = {
                  library = vim.api.nvim_get_runtime_file("", true),
                },
                runtime = {
                  version = "LuaJIT",
                },
                diagnostics = {
                  globals = { "hs" },
                },
              },
            },
          })
        end,
      })
      require("lsp.rime_ls").setup_rime()
      require("lsp.dictionary").dictionary_setup()

      lspconfig.texlab.setup({
        filetypes = { "tex", "bib" },
        -- offset_encoding = "utf-8", -- wtf? if not set, it shows warning
        capabilities = capabilities,
      })

      local pyright_capabilities = vim.lsp.protocol.make_client_capabilities()
      pyright_capabilities = require("blink.cmp").get_lsp_capabilities(pyright_capabilities)

      lspconfig.pyright.setup({
        capabilities = pyright_capabilities,
        settings = {
          python = {
            analysis = {
              diagnosticMode = "off",
              typeCheckingMode = "off",
            },
          },
        },
      })
    end,
  },
}
