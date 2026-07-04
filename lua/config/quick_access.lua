local M = {}

M.enabled = vim.env.KITTY_QUICK_ACCESS == "1"

function M.apply_to_current_window()
  if not M.enabled then
    return
  end

  vim.wo.number = false
  vim.wo.relativenumber = false
end

function M.apply()
  if not M.enabled then
    return
  end

  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.o.cmdheight = 0
  M.apply_to_current_window()

  local group = vim.api.nvim_create_augroup("QuickAccessCompactUi", { clear = true })
  vim.api.nvim_create_autocmd({ "UIEnter", "WinEnter", "BufWinEnter" }, {
    group = group,
    callback = M.apply_to_current_window,
  })
end

return M
