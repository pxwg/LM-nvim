return {
  "ice345/markdown-table-wrap.nvim",
  enabled = false,
  version = "^1",
  main = "markdown-table-wrap",
  ft = { "markdown", "md", "quarto", "rmd", "rmarkdown", "coact", "coact-history", "coact-input" },
  opts = {
    extra_filetypes = { "coact", "coact-history", "coact-input" },
    -- Keep Coact's original buffers, mappings, and streaming updates intact.
    -- Reader creates a replacement buffer and is unsuitable for chat windows.
    preview_mode = "inline",
    inline_mode = "replace",
    inline_wrap_scope = "always",
    render_all = true,
    auto_preview = true,
    -- Show raw Markdown while composing; render again after InsertLeave.
    auto_preview_in_insert = false,
    clear_on_insert = true,
  },
}
