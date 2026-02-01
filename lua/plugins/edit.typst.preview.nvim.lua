local function get_open_cmd()
  if vim.fn.has("mac") == 1 then
    return "kitten"
  elseif vim.fn.has("linux") then
    return "mac kitten"
  end
end

return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  priority = 1000,
  version = "1.*",
  opts = {
    -- port = 56000,
    -- debug = true,
    open_cmd = get_open_cmd()
      .. " @ --to unix:/tmp/mykitty launch --type window --title TypstPreview --dont-take-focus awrit %s",
    extra_args = {
      "--input=preview=true",
    },
    get_root = function(_)
      local dir = vim.fn.getcwd()
      return dir
    end,
    dependencies_bin = {
      ["tinymist"] = "tinymist",
      ["websocat"] = "websocat",
    },
  },
}
