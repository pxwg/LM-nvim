local M = {}

local function is_rime_ls_attached()
  local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  for _, client in ipairs(clients) do
    if client.name == "rime_ls" then
      return true
    end
  end
  return false
end

function M.check_rime_status()
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    if client.name == "rime_ls" then
      return true
    end
  end
  return false
end

local tex = require("util.latex")

local function rime_toggle_color()
  if M.check_rime_status() and rime_toggled then
    return { bg = "#74c7ec", fg = "#313244", gui = "bold" }
  elseif rime_ls_active then
    return tex.in_text() and { bg = "#f38ba8", fg = "#313244", gui = "bold" }
      or { bg = "#fab387", fg = "#313244", gui = "bold" }
  elseif not rime_toggled and not rime_ls_active then
    return tex.in_text() and { bg = "#74c7ec", fg = "#313244", gui = "bold" }
      or { bg = "#fab387", fg = "#313244", gui = "bold" }
  end
end

local function rime_toggle_word()
  if is_rime_ls_attached() then
    if M.check_rime_status() and _G.rime_toggled then
      return "cn"
    elseif _G.rime_ls_active and tex.in_latex() then
      return "math"
    elseif _G.rime_ls_active then
      return tex.in_text() and "error" or "math"
    elseif not _G.rime_toggled and not _G.rime_ls_active then
      return tex.in_text() and "en" or "math"
    end
  else
    return "en"
  end
end

M.rime_toggle_color = rime_toggle_color

M.rime_toggle_word = rime_toggle_word

return M
