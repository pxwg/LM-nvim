return {
  "noearc/jieba.nvim",
  event = "VeryLazy",
  dependencies = { "noearc/jieba-lua" },
  opts = {},
  keys = {
    { "n", "ce", ":lua require'jieba_nvim'.change_w()<CR>", { noremap = false, silent = true } },
    { "n", "de", ":lua require'jieba_nvim'.delete_w()<CR>", { noremap = false, silent = true } },
    { "n", "<leader>w", ":lua require'jieba_nvim'.select_w()<CR>", { noremap = false, silent = true } },
  },
}
