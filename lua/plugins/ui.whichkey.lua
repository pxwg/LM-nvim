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
      { "<leader>f", group = "File" }, -- group
      { "<C-/>", group = "Terminal" }, -- proxy to window mappings
      { "<leader>g", group = "Git" }, -- group
      { "<leader>e", group = "[E]xplorer Neotree (cwd)", icon = { icon = "󱏒", color = "red" } }, -- group
      { "<leader>E", group = "[E]xplorer Neotree (root)", icon = { icon = "󱏒", color = "orange" } }, -- group
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
