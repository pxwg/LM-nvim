return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  priority = 1000,
  version = "1.*",
  opts = function()
    local focus = require("util.zk_tinymist_focus")
    focus.setup()

    return {
      -- `zk-focus` makes include.typ read only the current note metadata.
      extra_args = { "--input=preview=true", "--input=zk-focus=true" },
      get_main_file = function(path)
        if focus.is_wiki_note_path(path) then
          return focus.focus_main()
        end
        return path
      end,
      get_root = function(path)
        if vim.fs.normalize(path) == focus.focus_main() then
          return focus.wiki_root()
        end
        return vim.fn.getcwd()
      end,
      dependencies_bin = {
        ["tinymist"] = "tinymist",
        ["websocat"] = "websocat",
      },
    }
  end,
}
