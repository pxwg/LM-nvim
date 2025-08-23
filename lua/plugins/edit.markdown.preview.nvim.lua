return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    event = { "VeryLazy" },
    enabled = true,
    run = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
    keys = {
      {
        "<leader>cp",
        ft = "markdown",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "Markdown Preview",
      },
    },
    config = function()
      vim.cmd([[do FileType]])
      vim.g.mkdp_filetypes = { "markdown", "html" }
      vim.cmd([[
  function OpenMarkdownPreview (url)
    execute "silent ! kitten @ --to unix:/tmp/mykitty launch --type window --title MarkdownPreview --dont-take-focus awrit " . a:url
  endfunction
      let g:mkdp_browserfunc = 'OpenMarkdownPreview'
      ]])
    end,
  },
  {
    "toppair/peek.nvim",
    event = { "VeryLazy" },
    enabled = false,
    build = "deno task --quiet build:fast",
    opts = { app = { "chromium", "--new-window" } },
    config = function()
      require("peek").setup()
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    end,
  },
}
