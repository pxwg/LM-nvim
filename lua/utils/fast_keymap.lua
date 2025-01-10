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

