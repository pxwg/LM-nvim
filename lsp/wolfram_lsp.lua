local root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1])

return {
  name = "wolfram-lsp",
  filetypes = { "mma" },
  cmd = {
    "/Applications/Wolfram.app/Contents/MacOS/WolframKernel",
    "kernel",
    "-noinit",
    "-noprompt",
    "-nopaclet",
    "-noicon",
    "-nostartuppaclets",
    "-run",
    'Needs["LSPServer`"];LSPServer`StartServer[]',
  },
  root_dir = root_dir,

  on_attach = function(client, bufnr)
    local ns = vim.lsp.diagnostic.get_namespace(client.id)

    vim.diagnostic.config({
      severity_sort = true,
      underline = true,
      virtual_text = {
        severity = { min = vim.diagnostic.severity.WARN },
      },
      signs = {
        severity = { min = vim.diagnostic.severity.WARN },
      },
    }, ns)
  end,
}
