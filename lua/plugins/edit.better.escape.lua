return {
  "max397574/better-escape.nvim",
  event = "InsertEnter",
  -- enabled = false,

  opts = {
    timeout = 200,
    default_mappings = false,
    mappings = {
      i = {
        j = {
          j = "<Esc>",
          n = function()
            require("lsp.rime_ls").toggle_rime()
            _G.rime_toggled = not _G.rime_toggled
            _G.rime_ls_active = not _G.rime_ls_active
          end,
        },
        -- cn characters
        -- ['"'] = {
        --   ["<CR>"] = function()
        --     if require("util.rime_ls").rime_toggle_word() == "cn" then
        --       vim.api.nvim_feedkeys("“”", "n", true)
        --       vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[<Left>]], true, true, true), "n", true)
        --       return ""
        --     else
        --       vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[""<Left>]], true, true, true), "n", true)
        --       return ""
        --     end
        --   end,
        -- },
        -- ["'"] = {
        --   ["<Space>"] = function()
        --     if require("util.rime_ls").rime_toggle_word() == "cn" then
        --       vim.api.nvim_feedkeys("‘’", "n", true)
        --       vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[<Left>]], true, true, true), "n", true)
        --     else
        --       vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[''<Left>]], true, true, true), "n", true)
        --       return ""
        --     end
        --   end,
        -- },

        -- k = {
        --   j = function()
        --     return require("luasnip").jumpable(-1) and "<Plug>luasnip-jump-prev"
        --       or "<c-\\><c-n>:call searchpair('[([{<|]', '', '[)\\]}>|]', 'b')<cr>a"
        --   end,
        -- },
      },
      c = {
        j = {
          j = "<Esc>",
        },
      },
      t = {
        j = {
          k = "<C-\\><C-n>",
        },
      },
      v = {
        j = {
          k = "<Esc>",
        },
      },
      s = {
        j = {
          k = "<Esc>",
        },
      },
    },
  },
}
