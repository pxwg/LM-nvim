return {
  name = "harper_ls",
  cmd = { "harper-ls", "--stdio" },
  filetypes = { "tex", "typst" },
  root_markers = {
    ".gitignore",
    ".git",
    "typst.toml",
    ".harper-dictionary.txt",
  },
  settings = {
    allowedFileTypes = { "tex", "typst" },
    markdown = {
      IgnoreLinkTitle = true,
      SpellCheck = false,
      Dashes = false,
    },
    ["harper-ls"] = {
      fileDictPath = require("util.cwd_attach").get_cwd() .. "/.harper_dict_local",
      linters = { LongSentences = false, OrthographicConsistency = false, ToDoHyphen = false, UnclosedQuotes = false },
    },
  },
}
