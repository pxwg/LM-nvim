require("util.lazyfile").lazy_file()
return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
  },
  -- enabled = false,
  lazy = vim.fn.argc(-1) == 0,
  event = { "LazyFile", "VeryLazy" },
  version = false, -- last release is way too old and doesn't work on Windows
  build = ":TSUpdate",
  opts = {},
  config = function()
    require("nvim-treesitter.configs").setup({
      ignore_install = {},
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "toml",
        "latex",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },

      -- Install parsers synchronously (only applied to `ensure_installed`)
      sync_install = false,
      -- Automatically install missing parsers when entering buffer
      -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
      auto_install = true,

      ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
      -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!
      modules = {},
      highlight = {
        enable = true,
        -- additional_vim_regex_highlighting = false,
        -- additional_vim_regex_highlighting = { "latex" },
      },
      indent = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = { ["a$"] = "@math.outer", ["i$"] = "@math.inner" },
        },
      },
    })
  end,
}
