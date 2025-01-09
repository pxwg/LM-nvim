local function greet_based_on_time()
  local hour = tonumber(os.date("%H"))
  if hour < 12 then
    return "Morning"
  elseif hour < 18 then
    return "Afternoon"
  else
    return "Evening"
  end
end

greet_based_on_time()
local function create_empty_buffer()
  vim.cmd("enew") -- 打开一个新的空缓冲区
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
end

local function set_keymaps_fzf()
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(0, 'n', 'c', ':lua require("fzf-lua").files({ cwd = "~/.config/nvim" })<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 'f', ':lua require("fzf-lua").files()<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 'g', ':lua require("fzf-lua").grep()<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 's', ':lua require("persistence").load({ last = true })<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 'l', ':Lazy<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 'r', ':lua require("fzf-lua").oldfiles()<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':q<cr>', opts)
end

local function set_keymaps_telescope()
  local opts = { noremap = true, silent = true }

  vim.api.nvim_buf_set_keymap(0, 'n', 'c', ':lua require("telescope.builtin").find_files({ cwd = "~/.config/nvim" })<cr>',
    opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 'f', ':lua require("telescope.builtin").find_files()<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 'g', ':lua require("telescope.builtin").live_grep()<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 's', ':lua require("persistence").load({ last = true })<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 'l', ':Lazy<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 'r', ':lua require("telescope.builtin").oldfiles()<cr>', opts)
  vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':q<cr>', opts)
end

local function set_keymaps()
  if vim.g.picker == "fzf" then
    set_keymaps_fzf()
  elseif vim.g.picker == "telescope" then
    set_keymaps_telescope()
  else
    error("Unknown picker: " .. vim.g.picker)
  end
end

local function get_centered_lines(lines)
  local width = vim.api.nvim_win_get_width(0)
  local height = vim.api.nvim_win_get_height(0)
  local padding_top = math.floor((height - #lines) / 2)

  for i, line in ipairs(lines) do
    local padding_left = math.floor((width - #line) / 2)
    lines[i] = string.rep(" ", padding_left) .. line
  end

  local centered_lines = {}
  for _ = 1, padding_top do
    table.insert(centered_lines, "")
  end
  for _, line in ipairs(lines) do
    table.insert(centered_lines, line)
  end

  return centered_lines
end

local function set_buffer_lines(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.modifiable = false
  vim.bo.readonly = true
end

local hi = "Good " .. greet_based_on_time() .. ", Doggie!"

local lines = {
  hi,
  "",
  "[F]ind Files       ",
  "[R]ecent Files     ",
  "[G]rep Words       ",
  "[C]onfig Files     ",
  "[S]ync Session     ",
  "[L]azy             ",
  "[Q]uit             ",
}

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 then
      create_empty_buffer()
      local centered_lines = get_centered_lines(lines)
      set_buffer_lines(centered_lines)
      set_keymaps()
    end
  end,
})
