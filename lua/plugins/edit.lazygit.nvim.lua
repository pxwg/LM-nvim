-- nvim v0.8.0
return {
  "kdheepak/lazygit.nvim",
  lazy = true,
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  -- order to load the plugin when the command is run for the first time
  keys = {
    { "<leader>gg", "<cmd>LazyGitCurrentFile<cr>", desc = "Lazy[G]it (cwd)" },
    { "<leader>gG", "<cmd>LazyGit<cr>", desc = "Lazy[G]it (Root)" },
  },
}
