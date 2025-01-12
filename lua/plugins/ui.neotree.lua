local function cwd()
  local file_dir = vim.fn.expand("%:p:h")
  local git_dir = vim.fn.system("git -C " .. file_dir .. " rev-parse --show-toplevel")
  if vim.v.shell_error == 0 then
    return vim.fn.trim(git_dir)
  else
    return file_dir
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
    { "3rd/image.nvim", lazy = true } -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  keys = {
    {
      "<leader>fe",
      function()
        local reveal_file = vim.fn.expand("%:p")
        local dir = cwd()
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
