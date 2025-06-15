return {
  "michaelb/sniprun",
  branch = "master",
  cmd = { "SnipRun" },
  build = "sh install.sh 1",
  lazy = true,
  -- do 'sh install.sh 1' if you want to force compile locally
  -- (instead of fetching a binary from the github release). Requires Rust >= 1.65

  config = function()
    require("sniprun").setup({
      borders = "rounded",
      -- display = { "Api" },
      display = { "TempFloatingWindow", "LongTempFloatingWindow", "VirtualText", "Classic" },
      -- repl_enable = { "Mathematica_original" },
      interpreter_options = {
        Mathematica_original = {
          use_javagraphics_if_contains = { "Plot" }, -- a pattern that need <<JavaGraphics
          wrap_all_lines_with_print = false, -- wrap all lines making sense to print with Print[.];
          wrap_last_line_with_print = true, -- wrap last line with Print[.]        },
        },
      },
    })
    vim.g.markdown_fenced_languages = { "javascript", "typescript", "bash", "lua", "go", "rust", "c", "cpp", "python" }
  end,
}
