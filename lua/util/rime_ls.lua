local M = {}

-- Legacy compatibility layer for util.rime_ls UI functions
-- Redirects to new core.input system while preserving UI functionality

local tex = require("util.latex")

-- Check if rime_ls is running
function M.check_rime_status()
  return require("core.input").rime.is_running()
end

-- Check if rime is attached to current buffer
local function is_rime_ls_attached()
  return require("core.input").rime.is_attached()
end

-- Rime toggle color for status line
local function rime_toggle_color()
  local state = require("core.input").state
  local rime_toggled = state.is_rime_toggled()
  local rime_ls_active = state.is_rime_active()
  
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

-- Rime toggle word for status line
local function rime_toggle_word()
  if is_rime_ls_attached() then
    local state = require("core.input").state
    local rime_toggled = state.is_rime_toggled()
    local rime_ls_active = state.is_rime_active()
    
    if M.check_rime_status() and rime_toggled then
      return "cn"
    elseif rime_ls_active and tex.in_latex() then
      return "math"
    elseif rime_ls_active then
      return tex.in_text() and "error" or "math"
    elseif not rime_toggled and not rime_ls_active then
      return tex.in_text() and "en" or "math"
    end
  else
    return "en"
  end
end

-- Change cursor color based on rime status
local function change_cursor_color()
  if rime_toggle_word() == "cn" then
    vim.cmd("highlight Cursor guifg=#313244 guibg=#74c7ec")
  else
    vim.cmd("highlight Cursor guifg=NONE guibg=NONE")
  end
end

-- Attach rime to buffer
function M.attach_rime_to_buffer(bufnr)
  require("core.input").attach_to_buffer(bufnr)
end

-- Start rime_ls daemon
function M.start_rime_ls()
  return require("core.input").rime.start_daemon()
end

-- Export functions
M.change_cursor_color = change_cursor_color
M.rime_toggle_color = rime_toggle_color
M.rime_toggle_word = rime_toggle_word

return M