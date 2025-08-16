return {
  name = "clangd",
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_dir = vim.fn.getcwd(),
}
