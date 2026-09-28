local M = {}

local function sync_conceal()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  -- Copy only the foreground so concealed text keeps its surrounding background.
  vim.api.nvim_set_hl(0, "Conceal", { fg = normal.fg, ctermfg = normal.ctermfg })
  for _, group in ipairs({ "@conceal", "@typ_inline_dollar.typst", "@conceal_dollar" }) do
    vim.api.nvim_set_hl(0, group, { link = "Conceal" })
  end
end

function M.apply(mode)
  assert(mode == "light" or mode == "dark", "Unknown theme mode: " .. tostring(mode))
  vim.o.background = mode
  vim.cmd.colorscheme("default")
  sync_conceal()
end

function M.setup()
  local group = vim.api.nvim_create_augroup("ThemeConceal", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = sync_conceal,
    desc = "Keep concealed text the same color as body text",
  })
  M.apply("light")
  vim.api.nvim_create_user_command("ThemeToggle", function()
    M.apply(vim.o.background == "light" and "dark" or "light")
  end, { desc = "Toggle built-in default light and dark themes" })
end

return M
