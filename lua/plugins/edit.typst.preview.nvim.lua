return {
  "chomosuke/typst-preview.nvim",
  lazy = false,
  version = "1.*",
  opts = {
    port = 56000,
    open_cmd = "kitten @ --to unix:/tmp/mykitty launch --type window --title TypstPreview --dont-take-focus awrit http://127.0.0.1:56000/",
    get_root = function(fname)
      local dir = require("util.cwd_attach").get_cwd(fname)
      return dir
    end,
  },
}
