local function get_git_or_file_dir()
  local git_dir = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 then
    return git_dir
  else
    return vim.fn.expand("%:p:h")
  end
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  command = "Neotree",
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
        require("neo-tree.command").execute({ toggle = true, reveal_file = reveal_file, dir = get_git_or_file_dir() })
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
  init = function()
    -- FIX: use `autocmd` for lazy-loading neo-tree instead of directly requiring it,
    -- because `cwd` is not set up properly.
    vim.api.nvim_create_autocmd("BufEnter", {
      group = vim.api.nvim_create_augroup("Neotree_start_directory", { clear = true }),
      desc = "Start Neo-tree with directory",
      once = true,
      callback = function()
        if package.loaded["neo-tree"] then
          return
        else
          local stats = vim.uv.fs_stat(vim.fn.argv(0))
          if stats and stats.type == "directory" then
            require("neo-tree")
          end
        end
      end,
    })
  end,
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
