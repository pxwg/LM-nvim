local M = {}

function M.make()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok, blink = pcall(require, "blink.cmp")
  if ok and blink and blink.get_lsp_capabilities then
    capabilities = blink.get_lsp_capabilities(capabilities)
  end
  return capabilities
end

return M
