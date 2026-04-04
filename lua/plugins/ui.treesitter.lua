return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    event = { "LazyFile", "VeryLazy" },
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    opts = {
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
        "typst",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },

      highlight = { enable = true },
      indent = { enable = true },
      folds = { enable = true },
    },
    config = function(_, opts)
      local TS = require("nvim-treesitter")
      TS.setup({
        ensure_installed = opts.ensure_installed,
      })

      local augroup = vim.api.nvim_create_augroup("my_treesitter_main", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        callback = function(ev)
          local ft = ev.match
          local lang = vim.treesitter.language.get_lang(ft) or ft

          local function has_query(query)
            return pcall(vim.treesitter.query.get, lang, query)
          end

          -- highlight
          if opts.highlight and opts.highlight.enable and has_query("highlights") then
            pcall(vim.treesitter.start, ev.buf, lang)
          end

          -- indent
          if opts.indent and opts.indent.enable and has_query("indents") then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end

          -- folds
          if opts.folds and opts.folds.enable and has_query("folds") then
            vim.wo[0][0].foldmethod = "expr"
            vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
          end
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    opts = {
      select = {
        enable = true,
        lookahead = true,
      },
      move = {
        enable = true,
        set_jumps = true,
      },
    },
    config = function(_, opts)
      require("nvim-treesitter-textobjects").setup(opts)

      local move = require("nvim-treesitter-textobjects.move")

      vim.keymap.set({ "n", "x", "o" }, "]e", function()
        move.goto_next_start("@math.outer", "textobjects")
      end, { desc = "Next math" })

      vim.keymap.set({ "n", "x", "o" }, "[e", function()
        move.goto_previous_start("@math.outer", "textobjects")
      end, { desc = "Prev math" })

      vim.keymap.set({ "n", "x", "o" }, "]s", function()
        move.goto_next_start("@section.outer", "textobjects")
      end, { desc = "Next section" })

      vim.keymap.set({ "n", "x", "o" }, "[s", function()
        move.goto_previous_start("@section.outer", "textobjects")
      end, { desc = "Prev section" })
    end,
  },
}
