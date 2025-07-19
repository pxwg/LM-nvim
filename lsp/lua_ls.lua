local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
capabilities.general.positionEncodings = { "utf-8", "utf-16" }

return {
  name = "lua_ls",
  filetypes = { "lua" },
  cmd = { "lua-language-server" },
  capabilities = capabilities,
  root_dir = vim.fn.getcwd(),
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = {
          vim.env.VIMRUNTIME .. "/lua/",
          vim.fn.stdpath("config") .. "/lua",
          "${3rd}/luv/library",
          vim.fn.expand("HOME") .. "/.hammerspoon/Spoons/EmmyLua.spoon/annotations",
        },
      },
      codeLens = {
        enable = true,
      },
      doc = {
        privateName = { "^_" },
      },
      hint = {
        enable = true,
        setType = false,
        paramType = true,
        paramName = "Disable",
        semicolon = "Disable",
        arrayIndex = "Disable",
      },
      runtime = {
        version = "LuaJIT",
        path = {
          "lua/?.lua",
          "lua/?/init.lua",
          vim.fn.stdpath("config") .. "/lua/?.lua",
          vim.fn.stdpath("config") .. "/lua/?/init.lua",
          "${3rd}/luv/library/?.lua",
        },
      },
      completion = {
        callSnippet = "Replace",
      },
    },
  },
}
