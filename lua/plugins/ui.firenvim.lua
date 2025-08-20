return {
  "glacambre/firenvim",
  build = ":call firenvim#install(0)",
  enabled = false,
  config = function()
    if vim.g.started_by_firenvim then
      vim.o.laststatus = 0
      vim.opt.guifont = "JetBrainsMono Nerd Font:20"
      vim.g.firenvim_config = {
        globalSettings = { alt = "all" },
        localSettings = {
          [".*"] = {
            cmdline = "neovim",
            content = "text",
            selector = "textarea",
            -- takeover = "never",
          },
        },
      }
    end
  end,
}
