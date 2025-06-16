return {
  "ravitemer/mcphub.nvim",
  build = "bundled_build.lua",
  config = function()
    require("mcphub").setup({ use_bundled_binary = true })
  end,
}
