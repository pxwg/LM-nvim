-- Catppuccin theme - configured in core but loaded as plugin
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000000,
    config = false, -- Configuration handled by core.ui
  },
}