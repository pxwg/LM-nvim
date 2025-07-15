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
    event = { "VeryLazy", "BufEnter", "BufReadPost", "BufWritePost", "BufNewFile" },
    version = "^1.0.0",
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
      servers = {
        lua_ls = {
          -- mason = false, -- set to false if you don't want this server to be installed with mason
          -- Use this to add any additional keymaps
          -- for specific lsp servers
          -- ---@type LazyKeysSpec[]
          -- keys = {},
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              codeLens = {
                enable = true,
              },
              completion = {
                callSnippet = "Replace",
              },
              doc = {
                privateName = { "^_" },
              },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = "Disable",
                semicolon = "Disable",
                arrayIndex = "Disable",
              },
            },
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
          server_config.settings = {
            Lua = {
              workspace = {
                library = vim.list_extend(vim.api.nvim_get_runtime_file("", true), {
                  vim.fn.stdpath("config") .. "/lua",
                  "${3rd}/luv/library",
                  vim.fn.expand("HOME") .. "/.hammerspoon/Spoons/EmmyLua.spoon/annotations",
                }),
              },
              runtime = {
                version = "LuaJIT",
                path = vim.list_extend(vim.split(package.path, ";"), {
                  "lua/?.lua",
                  "lua/?/init.lua",
                  vim.fn.stdpath("config") .. "/lua/?.lua",
                  vim.fn.stdpath("config") .. "/lua/?/init.lua",
                  "${3rd}/luv/library/?.lua",
                }),
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          }
          require("lspconfig")[server_name].setup(server_config)
        end,
      })
      require("lsp.rime_ls").setup_rime()
      require("lsp.dictionary").dictionary_setup()
      require("lsp.mma").setup_mma_lsp()
      require("lsp.tslsp").setup_ts_query_lsp()

      local path_spelling = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
      local spell_de = {}
      for word in io.open(path_spelling, "r"):lines() do
        table.insert(spell_de, word)
      end
      lspconfig.ltex.setup({
        capabilities = capabilities,
        settings = {
          ltex = {
            language = "en-US",
            dictionary = {
              ["en-US"] = spell_de,
            },
          },
        },
      })

      lspconfig.harper_ls.setup({
        -- Only attach to markdown and tex files
        on_attach = function(client, bufnr)
          local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
          if filetype ~= "markdown" and filetype ~= "tex" and filetype ~= "typst" then
            vim.schedule(function()
              vim.lsp.buf_detach_client(bufnr, client.id)
            end)
            return false
          end
          return true
        end,
        init_options = {
          allowedFileTypes = { "markdown", "tex", "typst" },
        },
        settings = {
          markdown = {
            IgnoreLinkTitle = true,
            SpellCheck = false,
            Dashes = false,
          },
          ["harper-ls"] = {
            fileDictPath = require("util.cwd_attach").get_cwd() .. "/.harper_dict_local",
            linters = { LongSentences = false },
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

      capabilities.general.positionEncodings = { "utf-8" }

      local rime_on_attach = function(client, _)
        local toggle_rime = function()
          client.request("workspace/executeCommand", { command = "rime-ls.toggle-rime" }, function(_, result, ctx, _)
            if ctx.client_id == client.id then
              vim.g.rime_enabled = result
            end
          end)
        end
        -- keymaps for executing command
        vim.keymap.set("n", "<leader>rr", toggle_rime, { desc = "Toggle [R]ime" })
        -- vim.keymap.set("i", "jn", toggle_rime, { desc = "Toggle Rime" })
        vim.keymap.set("n", "<leader>rs", function()
          vim.lsp.client:exec_cmd({ title = "rime-ls.sync-user-data", command = "rime-ls.sync-user-data" })
        end, { desc = "[R]ime [S]ync" })
        -- vim.keymap.set("i", "jn", function()
        --   require("lsp.rime_ls").toggle_rime()
        --   _G.rime_toggled = not _G.rime_toggled
        --   _G.rime_ls_active = not _G.rime_ls_active
        -- end, { noremap = true, silent = true, desc = "toggle rime-ls" })
      end

      local rime_ls_filetypes = { "vimwiki", "tex", "markdown", "copilot-chat", "Avante", "codecompanion", "typst" }
      lspconfig.rime_ls.setup({
        settings = {
          name = "rime_ls",
          single_file_support = true,
          autostart = true, -- Add this line to prevent automatic start, in order to boost
          filetypes = rime_ls_filetypes,
          enabled = vim.g.rime_enabled,
          cmd = { "rime-ls" },
          shared_data_dir = "/Library/Input Methods/Squirrel.app/Contents/SharedSupport",
          user_data_dir = "~/Library/Rime_2/",
          log_dir = vim.fn.expand("~/.local/share/rime-ls-1/"),
          paging_characters = { ",", "." },
          trigger_characters = {},
          schema_trigger_character = "&",
          always_incomplete = false,
          preselect_first = false,
          show_filter_text_in_label = false,
          max_candidates = 9,
          max_tokens = 0,
          long_filter_text = true,
          -- long_filter_text = false,
        },
        -- on_attach = attach_in_insert_mode,
        on_attach = rime_on_attach,
        capabilities = capabilities,
      })

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
