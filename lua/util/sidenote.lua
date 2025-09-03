local M = {}
local original_settings = {
  laststatus = vim.o.laststatus,
  cmdheight = vim.o.cmdheight,
  number = vim.o.number,
  relativenumber = vim.o.relativenumber,
  signcolumn = vim.o.signcolumn,
}

local is_small_window = false

local function adjust_ui_for_window_size()
  local width = vim.o.columns
  local height = vim.o.lines

  local should_be_minimal = width < 20 or height < 20

  if should_be_minimal and not is_small_window then
    is_small_window = true
    vim.schedule(function()
      vim.o.laststatus = 0
      vim.o.cmdheight = 0
      vim.wo.number = false
      vim.o.relativenumber = false
      vim.o.signcolumn = "no"
    end)
    local autogroup = vim.api.nvim_create_augroup("MinimalUI", { clear = true })
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = autogroup,
      callback = function()
        vim.schedule(function()
          vim.o.laststatus = 0
          vim.o.cmdheight = 0
          vim.wo.number = false
          vim.o.relativenumber = false
          vim.o.signcolumn = "no"
        end)
      end,
    })
  elseif not should_be_minimal and is_small_window then
    is_small_window = false
    vim.api.nvim_clear_autocmds({ group = "MinimalUI" })
    vim.schedule(function()
      vim.o.laststatus = original_settings.laststatus
      vim.o.cmdheight = original_settings.cmdheight
      vim.o.number = original_settings.number
      vim.o.relativenumber = original_settings.relativenumber
      vim.o.signcolumn = original_settings.signcolumn
    end)
  end
end

M.adjust_ui_for_window_size = adjust_ui_for_window_size
return M
