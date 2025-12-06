return {
  name = "clangd",
  cmd = { "clangd", "--compile-commands-dir=build.clang" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_dir = vim.fn.getcwd(),
}
