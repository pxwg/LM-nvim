-- require("util.lazyfile").lazy_file()
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
    event = { "VeryLazy", "BufEnter", "BufReadPost", "BufWritePost", "BufNewFile" },
    -- event = { "LazyFile" },
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

      vim.lsp.config.signature_help = {
        border = "rounded",
      }
      -- Load mason_lspconfig
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          -- if server_name.workspace_folders then
          --   local path = server_name.workspace_folders[1].name
          --   if
          --     path ~= vim.fn.stdpath("config")
          --     and (vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc"))
          --   then
          --     return
          --   end
          -- end
          require("lspconfig")[server_name].setup({
            -- offset_encoding = "utf-8", -- wtf? if not set, it shows warning
            capabilities = capabilities,
            root_dir = function(fname)
              return lspconfig.util.root_pattern(".git", "package.json", "pyproject.toml")(fname)
                or vim.fs.dirname(fname)
            end,
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
          })
        end,
      })
      require("lsp.rime_ls").setup_rime()

      lspconfig.texlab.setup({
        filetypes = { "tex", "bib" },
        -- offset_encoding = "utf-8", -- wtf? if not set, it shows warning
        capabilities = capabilities,
      })

      -- Register the dictionary LSP server first
      local configs = require("lspconfig.configs")
      if not configs.dictionary then
        configs.dictionary = {
          default_config = {
            filetypes = { "markdown", "copilot-chat" },
            cmd = { vim.fn.expand("~/dictionary_lsp/target/release/dictionary_lsp") },
            root_dir = function(fname)
              local startpath = fname
              return vim.fs.dirname(vim.fs.find(".git", { path = startpath, upward = true })[1]) or vim.fn.getcwd()
            end,
          },
        }
      end

      -- Then set it up
      lspconfig.dictionary.setup({
        capabilities = capabilities,
      })
    end,
  },
}
