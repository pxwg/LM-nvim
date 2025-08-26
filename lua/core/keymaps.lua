-- Core keymaps
-- Essential keymaps that don't depend on specific languages or plugins

local M = {}

local map = vim.keymap.set

M.setup = function()
  -- Better line movement (respect wrapped lines)
  map({ "n", "v" }, "j", "gj", { silent = true })
  map({ "n", "v" }, "k", "gk", { silent = true })

  -- Better line navigation
  map({ "n", "v" }, "L", "$", { silent = true })
  map({ "n", "v" }, "H", "^", { silent = true })

  -- Window navigation
  map("n", "<C-j>", "<C-w>j", { silent = true })
  map("n", "<C-k>", "<C-w>k", { silent = true })

  -- Platform-specific window navigation
  if vim.fn.has("linux") == 1 then
    map("n", "<F2>", "<C-w>h", { silent = true, desc = "Move to left window" })
    map("n", "<F3>", "<C-w>l", { silent = true, desc = "Move to right window" })
  end

  -- Better window splitting
  map("n", "<C-w>v", "", {
    noremap = true,
    silent = true,
    callback = function()
      vim.cmd("vsplit")
      vim.cmd("wincmd l")
    end,
  })

  -- Save functionality
  map({ "n", "v", "i" }, "<C-s>", function()
    require("conform").format()
    vim.cmd("w")
    vim.cmd("stopinsert")
  end, { noremap = true, silent = true })

  -- Undo and redo
  map({ "n" }, "<C-z>", "u", { silent = true })
  map("i", "<C-z>", "<C-o>u", { silent = true })

  -- Clear search highlight
  map("n", "<ESC>", function()
    vim.cmd("nohlsearch")
  end, { noremap = true, silent = true, desc = "Clear search highlight" })

  -- Search improvements
  map("n", "/", function()
    local success = pcall(function()
      vim.cmd("nunmap n")
    end)
    if not success then
      vim.api.nvim_feedkeys("/", "n", true)
    else
      vim.api.nvim_feedkeys("/", "n", true)
    end
  end, { noremap = true, silent = true })

  -- LSP keymaps (generic)
  map(
    { "n" },
    "<leader>sh",
    "<cmd>lua vim.lsp.buf.signature_help()<CR>",
    { noremap = true, silent = true, desc = "[S]ignature [H]elp" }
  )
  map(
    { "i" },
    "<C-d>",
    "<cmd>lua vim.lsp.buf.signature_help()<CR>",
    { noremap = true, silent = true, desc = "Show Signature Help" }
  )
  map("i", "<C-a>", "<cmd>:lua vim.lsp.buf.hover()<CR>", { noremap = true, silent = true, desc = "Show Hover" })

  -- Telescope-based LSP navigation (if telescope is the picker)
  if vim.g.picker == "telescope" then
    map("n", "gd", function()
      local cwd = vim.fn.getcwd()
      vim.cmd(string.format("Telescope lsp_definitions theme=cursor cwd=%s", cwd))
    end, { desc = "Goto [D]efinition" })
    map("n", "gr", function()
      local cwd = vim.fn.getcwd()
      vim.cmd(string.format("Telescope lsp_references theme=cursor cwd=%s", cwd))
    end, { desc = "[R]eferences", nowait = true })
    map("n", "gi", function()
      local cwd = vim.fn.getcwd()
      vim.cmd(string.format("Telescope lsp_implementations theme=cursor cwd=%s", cwd))
    end, { desc = "Goto [I]mplementation" })
    map("n", "gy", function()
      local cwd = vim.fn.getcwd()
      vim.cmd(string.format("Telescope lsp_type_definitions theme=cursor cwd=%s", cwd))
    end, { desc = "Goto T[y]pe Definition" })
  end

  -- Which-key
  map("n", "<leader>?", ":WhichKey<cr>", { desc = "Buffer Local Keymaps (which-key)" })

  -- Dim functionality
  map("n", "<leader>ud", "<cmd>Twilight<cr>", { silent = true, desc = "[D]im" })
end

return M