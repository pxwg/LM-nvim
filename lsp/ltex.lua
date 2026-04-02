local path_spelling = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
local spell_dic = {}
for word in io.open(path_spelling, "r"):lines() do
  table.insert(spell_dic, word)
end
local capabilities = require("util.lsp_capabilities").make()
capabilities.general.positionEncodings = { "utf-8", "utf-16" }
return {
  name = "ltex",
  cmd = "ltex",
  filetypes = { "tex" },
  capabilities = capabilities,
  settings = {
    ltex = {
      language = "en-US",
      dictionary = {
        ["en-US"] = spell_dic,
      },
    },
  },
}
