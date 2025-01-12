return {
  "max397574/better-escape.nvim",
  event = "InsertEnter",
  enabled = false,

  opts = {
    timeout = 600,
    default_mappings = false,
    mappings = {
      i = {
        j = {
          -- j = "<Esc>",
          k = function()
            return require("luasnip").expand_or_locally_jumpable() and "<Plug>luasnip-jump-next"
              or "<c-\\><c-n>:call searchpair('[([{<|]', '', '[)\\]}>|]', 'W')<cr>a"
          end,
          -- n = function()
          --   require("lsp.rime_ls").toggle_rime()
          -- end,
        },
        k = {
          j = function()
            return require("luasnip").jumpable(-1) and "<Plug>luasnip-jump-prev"
              or "<c-\\><c-n>:call searchpair('[([{<|]', '', '[)\\]}>|]', 'W')<cr>a"
          end,
        },
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
