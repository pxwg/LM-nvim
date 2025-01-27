return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  cmd = "WhichKey",
  config = function()
    local wk = require("which-key")
    wk.setup({
      preset = "helix",
      triggers = { "\\" }, -- no default triggers
    })
    wk.add({
      { "<leader>f", group = "[F]ind", icon = { icon = "", color = "blue" } }, -- group
      { "<C-/>", group = "Terminal" }, -- proxy to window mappings
      { "<leader>t", group = "[T]erminal" }, -- proxy to window mappings
      { "<leader>g", group = "[G]it", icon = { icon = "", color = "yellow" } }, -- group
      { "<leader>c", group = "[C]ode", icon = { icon = "󰅴", color = "green" } }, -- group
      { "<leader>a", group = "[A]i", icon = { icon = "", color = "red" } }, -- group
      { "<leader>s", group = "[S]earch", icon = { icon = "", color = "green" } }, -- group
      { "<leader>e", group = "[E]xplorer Neotree (cwd)", icon = { icon = "󱏒", color = "red" } }, -- group
      { "<leader>E", group = "[E]xplorer Neotree (root)", icon = { icon = "󱏒", color = "orange" } }, -- group
      { "<leader>n", group = "[N]ote", icon = { icon = "󰎞", color = "green" } },
      {
        "<leader>b",
        group = "buffers",
        expand = function()
          return require("which-key.extras").expand.buf()
        end,
      },
    })
  end,
}
