-- Blink completion - configured in core but loaded as plugin
return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*",
    dependencies = {
      "Kaiser-Yang/blink-cmp-avante",
      "L3MON4D3/LuaSnip",
      "ribru17/blink-cmp-spell",
      "zbirenbaum/copilot-cmp",
      "zbirenbaum/copilot.lua",
      "dmitmel/cmp-digraphs",
      "hrsh7th/cmp-nvim-lsp",
      "giuxtaposition/blink-cmp-copilot",
      {
        "saghen/blink.compat",
        opts = { impersonate_nvim_cmp = true, enable_events = true },
      },
      {
        "Kaiser-Yang/blink-cmp-dictionary",
        dependencies = { "nvim-lua/plenary.nvim" },
      },
    },
    config = false, -- Configuration handled by core.ui
  },
}

