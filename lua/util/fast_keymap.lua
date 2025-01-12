local M = {}

local function custom_keymap(key)
  local col = vim.fn.col('.')
  local line = vim.fn.getline('.')
  local next_char = line:sub(col - 1, col)
  local byte_count = vim.fn.strdisplaywidth(next_char)

  -- start of line
  if col == 1 or next_char == key then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<BS><BS>", true, false, true), 'n', true)
    print(next_char)
    print("1")
  elseif byte_count <= 2 then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<BS>", true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<BS>", true, false, true), 'n', true)
    print("2")
    -- CN words
  elseif byte_count > 2 then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<BS><BS>", true, false, true), 'n', true)
  end
end

local function custom_keymap_1(key)
  local col = vim.fn.col('.')
  local line = vim.fn.getline('.')
  local next_char = line:sub(col - 1, col)
  local byte_count = vim.fn.strdisplaywidth(next_char)

  -- start of line
  if col == 1 or next_char == key then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<BS><BS>", true, false, true), 'n', true)
    print(next_char)
    print("1")
  elseif byte_count <= 2 then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<BS>", true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<BS>", true, false, true), 'n', true)
    print("2")
    -- CN words
  elseif byte_count > 2 then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<BS><BS>", true, false, true), 'n', true)
  end
end

local function startinsert()
  vim.cmd("startinsert") -- Enter insert mode
  return 1
end

local function listen_for_key(timeout, key)
  local timer = vim.loop.new_timer()
  local timed_out = false

  startinsert()

  -- vim.api.nvim_input('a') -- Enter insert mode
  timer:start(timeout, 0, vim.schedule_wrap(function()
    startinsert()
    timed_out = true
    timer:stop()
    timer:close()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), 'n', true)
    return 1 -- Add return statement here
  end))

  -- local char_i = vim.fn.getchar(1)
  -- print(vim.fn.nr2char(char_i))
  -- vim.fn.getchar(1)
  local char = vim.fn.getchar()

  startinsert()
  -- vim.api.nvim_feedkeys('a' .. vim.fn.nr2char(char), 'n', true)
  vim.api.nvim_feedkeys(vim.fn.nr2char(char), 'n', true)
  local char_out = vim.fn.nr2char(char)
  if char ~= 0 and timed_out == false then
    if char_out == 'j' then
      custom_keymap('j')
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), 'n', true)

      timed_out = true
      timer:stop()
      timer:close()
      return 1
    elseif char_out == "n" then
      custom_keymap('n')
      vim.cmd("lua require('lsp.rime_ls').toggle_rime()")
      timed_out = true
      timer:stop()
      timer:close()
      return 1
    elseif char_out == "k" then
      -- custom_keymap('k')
      timer:stop()
      timer:close()
      -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, false, true), 'n', true)
      if require("luasnip").expand_or_locally_jumpable() then
        return "<Plug>luasnip-jump-next"
      else
        return "<c-\\><c-n>:call searchpair('[([{<|]', '', '[)\\]}>|]', 'W')<cr>a"
      end
    elseif char_out == '<BS>' then
      vim.api.nvim_fedkeys(vim.api.nvim_replace_termcodes("<BS><BS>", true, false, true), 'n', true)
      timed_out = true
      timer:stop()
      timer:close()
      return 1
    else
      custom_keymap_1(vim.fn.nr2char(char))
      vim.api.nvim_feedkeys(key .. vim.fn.nr2char(char), 'n', true)
      timed_out = true
      timer:stop()
      timer:close()
      return 1
    end
  end
end

M.listen_for_key = listen_for_key

return M
