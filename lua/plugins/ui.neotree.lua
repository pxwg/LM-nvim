local function get_git_or_file_dir()
  local git_dir = vim.fn.system("git rev-parse --show-toplevel")
  if vim.v.shell_error == 0 then
    return vim.fn.trim(git_dir)
  else
    return vim.fn.expand("%:p:h")
  end
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  command = "Neotree",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    "3rd/image.nvim",              -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  keys = {
    {
      "<leader>fe",
      function()
        local reveal_file = vim.fn.expand("%:p")
        local dir = get_git_or_file_dir()
        require("neo-tree.command").execute({ toggle = true, dir = dir, reveal_file = reveal_file })
      end,
      desc = "[E]xplorer NeoTree (cwd)",
    },
    {
      "<leader>fE",
      function()
        local reveal_file = vim.fn.expand("%:p")
        require("neo-tree.command").execute({ toggle = true, reveal_file = reveal_file, dir = vim.uv.cwd() })
      end,
      desc = "[E]xplorer NeoTree (Root Dir)",
    },
    { "<leader>e", "<leader>fe", desc = "[E]xplorer NeoTree (cwd)",      remap = true },
    { "<leader>E", "<leader>fE", desc = "[E]xplorer NeoTree (Root Dir)", remap = true },
  },
  opts = {
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
  }
}
