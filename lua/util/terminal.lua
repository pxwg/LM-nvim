local M = {}

local function add_terminal_key(buf)
  local esc_timer = nil
  vim.api.nvim_buf_set_keymap(buf, "t", "<ESC>", "", {
    noremap = true,
    silent = true,
    callback = function()
      esc_timer = esc_timer or vim.loop.new_timer()
      if esc_timer:is_active() then
        esc_timer:stop()
        vim.cmd("stopinsert")
      else
        esc_timer:start(200, 0, function() end)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "n", true)
      end
    end,
  })
  vim.api.nvim_buf_set_keymap(buf, "t", "<A-x>", "<C-\\><C-n>:q!<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<A-x>", "<C-\\><C-n>:q!<CR>", { noremap = true, silent = true })
end

local function open_terminal(layout)
  local buf = vim.api.nvim_create_buf(false, true)
  local win_height = math.floor(vim.o.lines * 0.4)
  local win_width = math.floor(vim.o.columns * 0.4)
  local row, col

  if layout == "l" then
    row = vim.o.lines - win_height
    col = vim.o.columns - win_width
  elseif layout == "k" then
    row = 0
    col = vim.o.columns - win_width
  elseif layout == "j" then
    row = 0
    col = 0
  elseif layout == "h" then
    row = vim.o.lines - win_height
    col = 0
  else
    row = vim.o.lines - win_height
    col = 0
  end

  local win_config = {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = "none",
    title = "Terminal - Press <C-x> to leave",
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)

  -- Open terminal
  vim.fn.termopen(vim.o.shell, {
    cwd = vim.fn.expand("%:p:h"),
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        vim.api.nvim_err_writeln("Terminal exited with code " .. exit_code)
      end
    end,
  })

  -- Set buffer keymap
  vim.api.nvim_buf_set_keymap(0, "n", "q", "<C-\\><C-n>:q!<CR>", { noremap = true, silent = true })
  add_terminal_key(0)
end

local terminal_buf = nil

local function open_terminal_split(key)
  -- Split the window vertically to the right
  key = key or "L"
  vim.cmd("vsplit")
  vim.cmd("wincmd " .. key)
  -- Resize the new split to 40% of the screen width
  vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.3))

  local current_file_path = vim.fn.expand(require("util.cwd_attach").cwd())
  local terminal_path = vim.fn.getcwd()

  if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) and terminal_path == current_file_path then
    -- If terminal buffer exists, is valid, and paths match, use it
    vim.cmd("buffer " .. terminal_buf)
  else
    vim.cmd("term")
    terminal_buf = vim.api.nvim_get_current_buf()
  end

  vim.api.nvim_buf_set_keymap(0, "n", "q", ":q<CR>", { noremap = true, silent = true })
  add_terminal_key(0)
end

M.open_terminal_split = open_terminal_split

M.open_terminal = open_terminal

return M
