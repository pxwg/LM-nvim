return {
  name = "harper_ls",
  cmd = { "harper-ls" },
  filetypes = { "markdown", "tex", "typst" },
  settings = {
    allowedFileTypes = { "markdown", "tex", "typst" },
    markdown = {
      IgnoreLinkTitle = true,
      SpellCheck = false,
      Dashes = false,
    },
    ["harper-ls"] = {
      fileDictPath = require("util.cwd_attach").get_cwd() .. "/.harper_dict_local",
      linters = { LongSentences = false },
    },
  },
}
