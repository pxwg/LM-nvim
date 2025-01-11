local M = {}
local function setup_keymap(mode, lhs, rhs, timeout)
  local first_char = lhs:sub(1, 1)
  local second_char = lhs:sub(2, 2)
  local timer_active = false
  local timer = vim.loop.new_timer()
  local inputed_first_char = false

  local function reset_state()
    timer:stop()
    timer_active = false
    inputed_first_char = false
  end

  local function on_first_char()
    inputed_first_char = true
    if timer_active then
      reset_state()
    end

    timer:start(timeout, 0, vim.schedule_wrap(function()
      reset_state()
    end))

    timer_active = true
  end

  local function on_second_char()
    if inputed_first_char then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(rhs, true, false, true), 'n', true)
      vim.api.nvim_feedkeys("x", 'n', true)
      vim.api.nvim_feedkeys("x", 'n', true)
      reset_state()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(second_char, true, false, true), 'n', true)
    end
  end

  vim.on_key(function(key)
    if key == first_char then
      on_first_char()
    elseif key == second_char then
      on_second_char()
    end
  end, vim.api.nvim_get_current_buf())
end

-- new timer to listen the newest key
local function listen_for_key(timeout)
  local timer = vim.loop.new_timer()
  local timed_out = false

  timer:start(timeout, 0, vim.schedule_wrap(function()
    timed_out = true
    timer:stop()
    timer:close()
  end))

  vim.api.nvim_input('a') -- Enter insert mode
  local char_i = vim.fn.getchar()
  print(vim.fn.nr2char(char_i))
  local char = vim.fn.getchar()

  if not timed_out then
    vim.api.nvim_feedkeys('a' .. vim.fn.nr2char(char), 'n', true)
    if char ~= 0 then
      if vim.fn.nr2char(char) == 'j' then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'n', true)
        vim.api.nvim_feedkeys("x", 'n', true)
        vim.api.nvim_feedkeys("x", 'n', true)
      end
    end
  end

  -- Ensure timer is stopped and closed after timeout
  vim.defer_fn(function()
    if not timed_out then
      timer:stop()
      timer:close()
    end
  end, timeout)
end

local function insert_a_if_normal_mode()
  local current_mode = vim.api.nvim_get_mode().mode
  if current_mode == 'n' then
    vim.api.nvim_input('a') -- 进入插入模式并插入 'a'
  end
end

local function listen_for_key(timeout)
  local timer = vim.loop.new_timer()
  local timed_out = false

  vim.api.nvim_input('a') -- Enter insert mode
  timer:start(timeout, 0, vim.schedule_wrap(function()
    timed_out = true
    timer:stop()
    timer:close()
    -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'n', true)
    -- vim.api.nvim_input('a') -- 进入插入模式
  end))

  local char_i = vim.fn.getchar()
  print(vim.fn.nr2char(char_i))
  local char = vim.fn.getchar()

  vim.api.nvim_feedkeys('a' .. vim.fn.nr2char(char), 'n', true)
  local char_out = vim.fn.nr2char(char)
  print(char_out)
  if char ~= 0 and timed_out == false then
    if char_out == 'j' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<BS><BS>", true, false, true), 'n', true)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'n', true)
      timed_out = true
      timer:stop()
      timer:close()
      return 1
    elseif char_out == "n" then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<BS><BS>", true, false, true), 'n', true)
      vim.cmd("lua require('lsp.rime_ls').toggle_rime()")
      timed_out = true
      timer:stop()
      timer:close()
      return 1
    end
  end

  -- Ensure timer is stopped and closed after timeout
  -- vim.defer_fn(function()
  --   if not timed_out then
  --     vim.api.nvim_input('a') -- 进入插入模式
  --     timer:stop()
  --     timer:close()
  --     return 2
  --   end
  -- end, timeout)
end

M.listen_for_key = listen_for_key

return M
