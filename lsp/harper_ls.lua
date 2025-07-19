return {
  name = "harper_ls",
  cmd = { "harper-ls" },
  filetypes = { "markdown", "tex", "typst" },
  -- Only attach to markdown and tex files
  -- init_options = {
  -- },
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
