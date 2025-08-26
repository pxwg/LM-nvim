-- Core keymaps
-- Essential keymaps that don't depend on specific languages or plugins

local M = {}

local function is_rightmost_window()
  local current_win = vim.api.nvim_get_current_win()
  local current_pos = vim.api.nvim_win_get_position(current_win)[2]
  local max_col = current_pos

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local pos = vim.api.nvim_win_get_position(win)[2]
    if pos > max_col then
      max_col = pos
    end
  end

  return current_pos == max_col
end

local function is_leftmost_window()
  local current_win = vim.api.nvim_get_current_win()
  local current_pos = vim.api.nvim_win_get_position(current_win)[2]
  local min_col = current_pos

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local pos = vim.api.nvim_win_get_position(win)[2]
    if pos < min_col then
      min_col = pos
    end
  end

  return current_pos == min_col
end

function ChNeovim()
  if is_leftmost_window() and vim.bo.filetype == "tex" then
    vim.fn.system("hs -c 'focusPreviousWindow()'")
  else
    vim.cmd("KittyNavigateLeft")
  end
end

function ClNeovim()
  if is_rightmost_window() and vim.bo.filetype == "tex" then
    vim.fn.system("hs -c 'focusPreviousWindow()'")
  else
    vim.cmd("KittyNavigateRight")
  end
end

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
