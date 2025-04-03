return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  command = "Neotree",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    { "3rd/image.nvim", lazy = true, build = true }, -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  keys = {
    {
      "g[",
      function()
        vim.cmd("cd ..//")
      end,
      desc = "[G]o to Parent Directory",
    },
    {
      "<leader>fe",
      function()
        local reveal_file = vim.fn.expand("%:p")
        local dir = require("util.cwd_attach").cwd()
        require("neo-tree.command").execute({ toggle = true, dir = dir, reveal_file = reveal_file })
      end,
      desc = "[E]xplorer NeoTree (cwd)",
    },
    {
      "<leader>fE",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = vim.fn.getcwd() })
      end,
      desc = "[E]xplorer NeoTree (Root Dir)",
    },
    { "<leader>e", "<leader>fe", desc = "[E]xplorer NeoTree (cwd)", remap = true },
    { "<leader>E", "<leader>fE", desc = "[E]xplorer NeoTree (Root Dir)", remap = true },
    -- { "<leader>cs", ":Neotree document_symbols<CR>" },
  },
  opts = {
    sources = { "filesystem", "git_status", "document_symbols" },
    source_selector = {
      winbar = true,
    },
    window = {
      mappings = {
        ["l"] = "open",
        ["h"] = "close_node",
        ["<space>"] = "none",
        ["Y"] = {
          function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg("+", path, "c")
          end,
          desc = "Copy Path to Clipboard",
        },
        ["O"] = {
          function(state)
            require("lazy.util").open(state.tree:get_node().path, { system = true })
          end,
          desc = "Open with System Application",
        },
        ["P"] = { "toggle_preview", config = { use_float = false } },
      },
    },
  },
}
