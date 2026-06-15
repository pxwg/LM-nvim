return {
  name = "porter.nvim",
  dir = vim.fn.stdpath("config"),
  event = "VeryLazy",
  config = function()
    local function markdown_to_typst(ctx)
      return require("user.transforms").markdown_to_typst(ctx)
    end

    require("porter").setup({
      override_paste = true,
      routes = {
        {
          name = "markdown-to-typst",
          from = { filetype = "markdown" },
          to = { filetype = "typst" },
          transform = markdown_to_typst,
        },
        {
          name = "codex-history-to-typst",
          from = { filetype = "codex-history" },
          to = { filetype = "typst" },
          transform = markdown_to_typst,
        },
      },
    })
  end,
}
