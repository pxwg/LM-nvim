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

local function create_empty_buffer()
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
end

local function set_keymaps(picker)
  local opts = { noremap = true, silent = true }
  local mappings = {
    c = picker == "fzf" and ':lua require("fzf-lua").files({ cwd = "~/.config/nvim" })<cr>'
      or ':lua require("telescope.builtin").find_files({ cwd = "~/.config/nvim" })<cr>',
    f = picker == "fzf" and ':lua require("fzf-lua").files()<cr>'
      or ':lua require("telescope.builtin").find_files()<cr>',
    g = picker == "fzf" and ':lua require("fzf-lua").grep()<cr>' or ':lua require("telescope.builtin").live_grep()<cr>',
    s = ':lua require("persistence").load({ last = true })<cr>',
    l = ":Lazy<cr>",
    r = picker == "fzf" and ':lua require("fzf-lua").oldfiles()<cr>'
      or ':lua require("telescope.builtin").oldfiles()<cr>',
    q = ":q<cr>",
    p = ":cd ~/Desktop/physics/notes/<cr>",
  }
  for key, cmd in pairs(mappings) do
    vim.api.nvim_buf_set_keymap(0, "n", key, cmd, opts)
  end
end

local function set_buffer_lines(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.modifiable = false
  vim.bo.readonly = true

  local start_line, end_line, target_line, target_col
  local start_cols, end_cols = {}, {}
  for i, line in ipairs(lines) do
    if line:match("%[.-%]") then
      start_line = start_line or i
      end_line = i
      local start_col = line:find("%[")
      local end_col = line:find("%]") + 1
      start_cols[i] = start_col
      end_cols[i] = end_col
      if not target_line then
        target_line = i
        target_col = start_col
      end
    end
  end

  if target_line and target_col then
    vim.api.nvim_win_set_cursor(0, { target_line, target_col })
  end

  if start_line and end_line then
    local function set_keymap(key, condition, cmd)
      vim.api.nvim_buf_set_keymap(
        0,
        "n",
        key,
        ":lua if " .. condition .. ' then vim.cmd("normal! ' .. cmd .. '") end<CR>',
        { noremap = true, silent = true }
      )
    end
    set_keymap("j", 'vim.fn.line(".") < ' .. end_line, "j")
    set_keymap("k", 'vim.fn.line(".") > ' .. start_line, "k")
    set_keymap("h", 'vim.fn.col(".") > ' .. start_cols[vim.fn.line(".")], "h")
    set_keymap("l", 'vim.fn.col(".") < ' .. end_cols[vim.fn.line(".")], "l")
    set_keymap("0", 'vim.fn.col(".") > ' .. start_cols[vim.fn.line(".")], "^")
    set_keymap("$", 'vim.fn.col(".") < ' .. end_cols[vim.fn.line(".")], "$")
    set_keymaps(vim.g.picker)
  end
end

local function get_centered_lines(lines)
  local centered_lines = {}
  local width = vim.api.nvim_get_option_value("columns", {})
  local height = vim.api.nvim_get_option_value("lines", {})
  local padding_top = math.floor((height - #lines) / 2)

  for _ = 1, padding_top do
    table.insert(centered_lines, "")
  end

  for _, line in ipairs(lines) do
    local padding_left = math.floor((width - #line) / 2)
    table.insert(centered_lines, string.rep(" ", padding_left) .. line)
  end

  for _ = 1, padding_top do
    table.insert(centered_lines, "")
  end

  return centered_lines
end

local hi = "Good " .. greet_based_on_time() .. ", Doggie!"

local lines = {
  hi,
  "",
  "[F]ind Files       ",
  "[R]ecent Files     ",
  "[P]hysics Notes    ",
  "[G]rep Words       ",
  "[C]onfig Files     ",
  "[S]ync Session     ",
  "[L]azy             ",
  "[Q]uit             ",
  "",
}

vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    if vim.fn.argc() == 0 then
      vim.cmd("only")
      create_empty_buffer()
      local centered_lines = get_centered_lines(lines)
      set_buffer_lines(centered_lines)
      vim.cmd("setfiletype hello")
    end
    vim.cmd("only")
  end,
})
