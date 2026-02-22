local map = vim.keymap.set

map("n", "<leader>ft", function()
  Snacks.picker.todo_comments({
    cwd = vim.fn.expand("%:p:h"),
    filter = { tag = { "NOTE" } },
  })
end, { noremap = true, silent = true })
