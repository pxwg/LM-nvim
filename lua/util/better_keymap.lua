local M = {}

local function listen_for_key(timeout)
  local timer = vim.loop.new_timer()
  local timed_out = false

  local char_i = vim.fn.getchar(1)   -- Non-blocking getchar for the second input
  print(vim.fn.nr2char(char_i))
  -- Enter insert mode
  vim.api.nvim_input('a')

  -- Start the timer
  timer:start(timeout, 0, vim.schedule_wrap(function()
    timed_out = true
    timer:stop()
    timer:close()
  end))

  -- Poll for key input
  while not timed_out do
    local char = vim.fn.getchar(1) -- Non-blocking getchar for the second input
    if char ~= 0 then
      local char_out = vim.fn.nr2char(char)
      print(char_out)
      break
    end
    vim.wait(10) -- Wait for 10ms before polling again
  end

  -- Ensure timer is stopped and closed after timeout
  if not timed_out then
    timer:stop()
    timer:close()
  end
end

M.listen_for_key = listen_for_key

return M
