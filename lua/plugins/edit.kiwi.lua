return {
  "serenevoid/kiwi.nvim",
  -- enabled = false,
  opts = {
    {
      name = "work",
      path = "/Users/pxwg-dogggie/work-wiki",
    },
    {
      name = "personal",
      path = "/Users/pxwg-dogggie/personal-wiki",
    },
  },
  keys = {
    { "<leader>nw", ':lua require("kiwi").open_wiki_index("work")<cr>', desc = "[N]ote [W]iki" },
    { "<leader>np", ':lua require("kiwi").open_wiki_index("personal")<cr>', desc = "[N]ote [P]ersonal" },
    { "T", ':lua require("kiwi").todo.toggle()<cr>', desc = "[T]oggle Markdown Task" },
  },
  lazy = true,
}
