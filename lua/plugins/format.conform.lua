return {
  "stevearc/conform.nvim",
  event = "BufReadPre",
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format()
      end,
      desc = "[C]ode [F]ormatter",
    },
  },
  opts = {
    log_level = vim.log.levels.DEBUG,
    remove_trailing_blanks = {
      fn = function(bufnr)
        -- Get buffer content
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        -- Find the last non-blank line
        local last_non_blank = #lines
        while last_non_blank > 0 and lines[last_non_blank]:match("^%s*$") do
          last_non_blank = last_non_blank - 1
        end

        -- If there are trailing blank lines
        if last_non_blank < #lines then
          -- Keep only non-blank lines
          local new_lines = vim.list_slice(lines, 1, last_non_blank)
          -- Return the changes
          return {
            {
              start = 0, -- Start at beginning of buffer
              finish = #lines - 1, -- End at last line of buffer
              replacement = new_lines,
            },
          }
        end

        -- No changes needed
        return {}
      end,
    },
    formatters = {
      trimlines = {
        command = vim.fn.stdpath("config") .. "/trim_blank_fmt/target/release/trim_blank_fmt",
        args = { "--input", "-" },
        stdin = true,
      }, -- HACK: a hacky way to avoid trailing blank lines
      ["tex-fmt"] = {
        command = "tex-fmt",
        args = { "--nowrap", "--stdin" },
        -- args = { "--stdin" },
        stdin = true,
      },
    },
    formatters_by_ft = {
      lua = { "stylua", "injected" },
      html = { "htmlbeautifier" },
      plaintex = {
        "autocorrect",
        -- "latexindent",
        "tex-fmt",
        "trimlines",
      },
      -- mma = { "wolfram-lsp" },
      tex = function()
        local file_path = vim.api.nvim_buf_get_name(0)
        local disable_dir = { "chiral_def_brst" }
        if vim.tbl_contains(disable_dir, vim.fn.fnamemodify(file_path, ":p:h:t")) then
          return { "trimlines" }
        end
        return {
          "autocorrect",
          -- "latexindent",
          "tex-fmt",
          "trimlines",
        }
      end,
      yml = { "yq" },
      typst = { "typstyle", "autocorrect", "trimlines" },
      arduino = { "clang_format" },
      typescript = { "prettier" },
      astro = { "prettier" },
      json = { "fixjson" },
      javascript = { "prettier", "injected" },
      toml = { "taplo" },
      cpp = { "clang_format" },
      objc = { "clang_format" },
      markdown = {
        -- { "/Users/pxwg-dogggie/trim_blank_fmt/target/release/trim_blank_fmt" },
        "autocorrect",
        "trimlines",
        -- "prettier", --- sooooooo slow
        "injected",
      },
      rust = { "rustfmt" },
      python = function(bufnr)
        if require("conform").get_formatter_info("ruff_format", bufnr).available then
          return { "ruff_format" }
        else
          return { "isort", "black" }
        end
      end,
      -- markdown = { "autocorrect", "prettier" },
    },
    -- format_on_save = {
    --   timeout_ms = 500,
    --   lsp_format = "fallback",
    -- },
    ignore_errors = false,
    -- Map of treesitter language to filetype
    lang_to_ft = {
      bash = "sh",
    },
    -- Map of treesitter language to file extension
    -- A temporary file name with this extension will be generated during formatting
    -- because some formatters care about the filename.
    lang_to_ext = {
      lua = "lua",
      bash = "sh",
      c_sharp = "cs",
      elixir = "exs",
      javascript = "js",
      julia = "jl",
      latex = "tex",
      markdown = "md",
      python = "py",
      ruby = "rb",
      rust = "rs",
      teal = "tl",
      typescript = "ts",
    },
  },
}
