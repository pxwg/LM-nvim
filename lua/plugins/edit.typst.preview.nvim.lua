return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  priority = 1000,
  version = "1.*",
  opts = {
    -- port = 56000,
    open_cmd = "kitten @ --to unix:/tmp/mykitty launch --type window --title TypstPreview --dont-take-focus awrit %s",
    extra_args = {
      "--input=preview=true",
    },
    get_root = function(fname)
      local dir = require("util.cwd_attach").get_cwd(fname)
      return dir
    end,
  },
}
