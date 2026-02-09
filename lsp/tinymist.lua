local function tinymist_on_attach(client, bufnr)
  if not client or client.name ~= "tinymist" then
    return
  end
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local root_markers = client.config.root_markers or {}
  local root = require("lspconfig.util").root_pattern(unpack(root_markers))(bufname) or vim.fs.dirname(bufname)
  local main_file = root .. "/index.typ"

  if vim.fn.filereadable(main_file) == 1 then
    client:request("workspace/executeCommand", {
      title = "pin",
      command = "tinymist.pinMain",
      arguments = { main_file },
    }, function(err, result)
      if err then
        vim.notify("Tinymist Pin Error: " .. vim.inspect(err), vim.log.levels.ERROR)
      else
      end
    end, bufnr)
  end
end

return {
  name = "tinymist",
  root_markers = {
    ".gitignore",
    ".git",
    "typst.toml",
  },
  cmd = { "tinymist" },
  filetypes = { "typst" },
  capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities()),
  on_attach = tinymist_on_attach,
  settings = {
    tinymist = {
      projectResolution = "lockDatabase",
      preview = { invertColors = "auto" },
      fontPaths = { "${workspaceFolder}/assets/fonts" },
    },
  },
}
