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
    version = "^1.0.0",
    event = { "LazyFile" },
    cmd = "LspStart",
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
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
      capabilities.general.positionEncodings = { "utf-8", "utf-16" }

      -- Load mason_lspconfig safely
      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup_handlers({
        function(server_name)
          local server_config = {
            capabilities = capabilities,
            root_dir = function(fname)
              local dir = require("util.cwd_attach").get_cwd(fname)
              return dir
            end,
          }

          -- Special configuration for lua_ls
          if server_name == "lua_ls" then
            server_config.settings = {
              Lua = {
                workspace = {
                  library = vim.list_extend(vim.api.nvim_get_runtime_file("", true), {
                    vim.fn.stdpath("config") .. "/lua",
                    "${3rd}/luv/library",
                  }),
                  maxPreload = 2000,
                  preloadFileSize = 50000,
                  checkThirdParty = false,
                },
                runtime = {
                  version = "LuaJIT",
                  path = vim.list_extend(vim.split(package.path, ";"), {
                    "lua/?.lua",
                    "lua/?/init.lua",
                    vim.fn.stdpath("config") .. "/lua/?.lua",
                    vim.fn.stdpath("config") .. "/lua/?/init.lua",
                  }),
                },
                diagnostics = {
                  globals = { "hs", "vim" },
                  disable = { "missing-fields" },
                },
                completion = {
                  callSnippet = "Replace",
                },
              },
            }
          end

          require("lspconfig")[server_name].setup(server_config)
        end,
      })
      require("lsp.rime_ls").setup_rime()
      require("lsp.dictionary").dictionary_setup()
      require("lsp.mma").setup_mma_lsp()

      -- Harper_ls - explicitly limited to markdown and tex files only
      lspconfig.harper_ls.setup({
        filetypes = { "markdown", "tex" },
        capabilities = capabilities,
        -- Only attach to markdown and tex files
        on_attach = function(client, bufnr)
          local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
          if filetype ~= "markdown" and filetype ~= "tex" then
            vim.schedule(function()
              vim.lsp.buf_detach_client(bufnr, client.id)
            end)
            return false
          end
          return true
        end,
        init_options = {
          allowedFileTypes = { "markdown", "tex" },
        },
        settings = {
          markdown = {
            IgnoreLinkTitle = true,
          },
          ["harper-ls"] = {
            linters = {
              -- Disable spell checking
              SpellCheck = false,
              Dashes = false,
            },
          },
        },
      })

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
