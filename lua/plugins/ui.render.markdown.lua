return {
  -- Make sure to set this up properly if you have lazy=true
  "MeanderingProgrammer/render-markdown.nvim",
  event = "UIEnter",
  opts = {
    file_types = { "markdown", "Avante", "copilot-chat" },
    heading = {
      sign = false,
      icons = { "󰼏 ", "󰎨 " },
      position = "inline",
      width = "block",
      left_margin = 0.5,
      left_pad = 0.2,
      right_pad = 0.2,
    },
  },
}
