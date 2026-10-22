return {
  dir = "/Users/pxwg-dogggie/coact-pi.nvim",
  name = "coact-pi.nvim",
  enabled = false,
  lazy = false, -- Also available to Pi's /nvim handoff without invoking :Coact first.
  main = "coact",
  opts = {
    node = "/Users/pxwg-dogggie/.nvm/versions/node/v24.13.0/bin/node",
  },
  keys = {
    { "<C-c>", "<cmd>Coact new<cr>", desc = "Coact Pi New Task" },
    { "<leader>ac", "<cmd>Coact list<cr>", desc = "Coact Pi Conversations" },
    { "<leader>aC", "<cmd>Coact new<cr>", desc = "Coact Pi New Task" },
  },
}
