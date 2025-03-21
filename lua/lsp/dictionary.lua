local M = {}

function M.dictionary_setup()
  local dictionary_filetypes = { " vimwiki", "tex", "markdown", "copilot-chat", "Avante" }
  local configs = require("lspconfig.configs")
  vim.g.dict_enabled = false
  local lspconfig = require("lspconfig")
  -- Register the dictionary LSP server first
  if not configs.dictionary then
    configs.dictionary = {
      default_config = {
        filetypes = dictionary_filetypes,
        cmd = { vim.fn.expand("~/dictionary_lsp/target/release/dictionary_lsp") },
        autostart = true,
        single_file_support = true,
        root_dir = function(fname)
          local startpath = fname
          return vim.fs.dirname(vim.fs.find(".git", { path = startpath, upward = true })[1]) or vim.fn.getcwd()
        end,
      },
    }
  end
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  -- capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
  -- capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
  capabilities.general.positionEncodings = { "utf-8" }

  -- Then set it up
  lspconfig.dictionary.setup({
    capabilities = capabilities,
  })
end

function M.toggle_dictionary()
  local client = vim.lsp.get_clients({ name = "dictionary" })[1]
  if client then
    client.request("workspace/executeCommand", { command = "dictionary.toggle-cmp" }, function(_, result, ctx, _)
      if ctx.client_id == client.id then
        vim.g.dict_enabled = result
      end
    end)
  end
end

return M
