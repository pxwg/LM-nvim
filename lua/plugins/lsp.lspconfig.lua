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
            offset_encoding = "utf-8", -- wtf? if not set, it shows warning
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
    end,
  },
}
