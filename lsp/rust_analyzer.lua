return {
  name = "rust_analyzer",
  cmd = { vim.fn.expand(vim.fn.stdpath("data")) .. "/mason/bin/rust-analyzer" },
  filetypes = { "rust" },
  root_dir = vim.fn.getcwd(),
}
