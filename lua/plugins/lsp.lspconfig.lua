return {
  "neovim/nvim-lspconfig",
  event = "UIEnter",
  config = function()
    local lspconfig = require("lspconfig")

    lspconfig.texlab.setup {
      filetypes = { "tex", "bib" },
    }

    lspconfig.lua_ls.setup {
      filetypes = { "lua" },
      settings = {
        Lua = {
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
          },
        },
      },
    }

    require("lsp.rime_ls").setup_rime()

    -- Add key mappings
  end,
}
