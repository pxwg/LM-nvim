local M = {}

function M.hammerspoon_enabled()
  return vim.fn.has("mac") == 1 and vim.env.TERMINFO:find("sidenote") == nil
end

function M.hammerspoon_load()
  local function get_front_window_id_async(callback)
    local stdout = vim.loop.new_pipe(false)
    local handle
    handle = vim.loop.spawn("hs", {
      args = { "-c", "GetWinID()" },
      stdio = { nil, stdout, nil },
    }, function()
      stdout:read_stop()
      stdout:close()
      handle:close()
    end)
    local output = ""
    stdout:read_start(function(err, data)
      assert(not err, err)
      if data then
        output = output .. data
      else
        local win_id = output:match("%d+")
        callback(win_id)
      end
    end)
  end

  get_front_window_id_async(function(current_win)
    if not current_win then
      return
    end
    vim.schedule(function()
      local log_dir = vim.fn.expand("~/.local/state/nvim/windows/")
      local log_file = log_dir .. current_win .. "_nvim_startup.log"
      local servername = vim.fn.eval("v:servername")
      vim.loop.fs_mkdir(log_dir, 448, function() -- 448 = 0o700
        vim.loop.fs_open(log_file, "w", 420, function(err, fd)
          if err or not fd then
            return
          end
          local content = current_win .. "\n" .. servername
          vim.loop.fs_write(fd, content, -1, function()
            vim.loop.fs_close(fd)
          end)
        end)
      end)
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          vim.loop.fs_unlink(log_file, function() end)
        end,
      })
    end)
  end)
end

return M
