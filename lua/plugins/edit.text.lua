-- Text editing enhancements: movement, snippets, and text manipulation
return {
  -- Better escape sequences
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
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
        },
        c = {
          j = {
            j = "<Esc>",
          },
        },
        n = {},
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
  },

  -- Text surround operations
  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },

  -- LuaSnip for snippet expansion
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    config = function()
      require("luasnip").config.set_config({
        enable_autosnippets = true,
        store_selection_keys = "`",
        delete_check_events = "TextChanged",
      })
      require("luasnip.loaders.from_lua").lazy_load({ paths = "~/.config/nvim/luasnip/" })
      local auto_expand = require("luasnip").expand_auto
      require("luasnip").expand_auto = function(...)
        vim.o.undolevels = vim.o.undolevels
        auto_expand(...)
      end
    end,
    keys = function()
      return {
        {
          "<C-k>",
          function()
            return require("luasnip").expand_or_locally_jumpable() and "<Plug>luasnip-jump-next"
              or "<c-\\><c-n>:call searchpair('[([{<|\"''《]', '', '[)\\]}>|\"''》]', 'W')<cr>a"
          end,
          expr = true,
          silent = true,
          mode = "i",
        },
        {
          "<C-k>",
          function()
            return require("luasnip").jump(1)
          end,
          mode = "s",
        },
        {
          "<S-Tab>",
          function()
            require("luasnip").jump(-1)
          end,
          mode = { "i", "s" },
        },
        {
          "<C-j>",
          function()
            require("luasnip").jump(-1)
          end,
          mode = { "i", "s" },
        },
        {
          "<c-b>",
          "<Plug>luasnip-next-choice",
          mode = { "i", "s" },
        },
        {
          "<c-p>",
          "<Plug>luasnip-prev-choice",
          mode = { "i", "s" },
        },
      }
    end,
  },

  -- Chinese word segmentation
  {
    "kkew3/jieba.vim",
    tag = "v1.0.5",
    build = "./build.sh",
    init = function()
      vim.g.jieba_vim_lazy = 1
      vim.g.jieba_vim_keymap = 1
    end,
  },
}
