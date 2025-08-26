-- Core autocmds
-- Essential autocmds that don't depend on specific languages or plugins

local M = {}

local autocmd = vim.api.nvim_create_autocmd

M.setup = function()
  -- Auto save cursor position
  autocmd("BufWinLeave", {
    pattern = "*",
    callback = function()
      vim.cmd("silent! mkview")
    end,
  })

  autocmd("BufReadPost", {
    pattern = "*",
    callback = function()
      vim.cmd("silent! loadview")
    end,
  })

  -- Set relativenumber when entering and unset for special file types
  autocmd("UIEnter", {
    callback = function()
      vim.cmd("setlocal relativenumber")
      vim.cmd("setlocal number")
    end,
  })

  autocmd("FileType", {
    pattern = "hello",
    callback = function()
      vim.cmd("setlocal norelativenumber")
      vim.cmd("setlocal nonumber")
    end,
  })

  -- Clean up special buffers on exit
  autocmd("VimLeavePre", {
    callback = function()
      local bufs = vim.api.nvim_list_bufs()
      for _, buf in ipairs(bufs) do
        if vim.bo[buf].filetype == "neo-tree" or vim.bo[buf].filetype == "copilot-chat" then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
    end,
  })

  -- Window resize handling
  autocmd("VimResized", {
    callback = function()
      vim.cmd("wincmd =")
    end,
  })

  -- Quickfix window keybindings
  autocmd("FileType", {
    pattern = "qf",
    callback = function()
      vim.api.nvim_buf_set_keymap(0, "n", "q", "<cmd>q<cr>", { noremap = true, silent = true })
    end,
  })

  -- Color preview for all files
  autocmd("BufRead", {
    callback = function()
      vim.cmd("ColorizerAttachToBuffer")
    end,
  })

  -- Handle clipboard for different platforms
  if vim.fn.has("linux") == 1 then
    vim.g.clipboard = {
      name = "orbstack-clipboard",
      copy = {
        ["+"] = { "orbctl", "clip" },
        ["*"] = { "orbctl", "clip" },
      },
      paste = {
        ["+"] = { "orbctl", "paste" },
        ["*"] = { "orbctl", "paste" },
      },
      cache_enabled = false,
    }
  end
end

return M