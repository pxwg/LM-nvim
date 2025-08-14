local M = {}
local tex = require("util.latex")
local typst = require("util.typst")
_G.rime_toggled = true
_G.rime_ls_active = true
_G.rime_math = false

local function in_math()
  return tex.in_mathzone() or typst.in_math()
end

local function switch_rime_math()
  -- if vim.bo.filetype == "tex" or vim.bo.filetype == "typst" then
  -- in the mathzone or table or tikz and rime is active, disable rime
  if (in_math() == true or tex.in_tikz() == true) and rime_ls_active == true then
    if _G.rime_toggled == true then
      require("lsp.rime_ls").toggle_rime()
      _G.rime_toggled = false
      _G.rime_math = true
    end
    -- in the text but rime is not active(by hand), do nothing
  elseif _G.rime_ls_active == false then
    -- in the text but rime is active(by hand ), thus the configuration is for mathzone or table or tikz
  else
    if (_G.rime_toggled == false and _G.changed_by_this == false) or (_G.rime_toggled == false and _G.rime_math) then
      require("lsp.rime_ls").toggle_rime()
      _G.rime_toggled = true
    end
    if (_G.rime_toggled == false and _G.changed_by_this) or (_G.rime_math == false and not _G.rime_toggled) then
    end
    if _G.rime_ls_active and _G.rime_toggled then
    end
  end
  -- end
end

local function force_toggle_rime()
  require("lsp.rime_ls").toggle_rime()

  if _G.rime_toggled == true then
    _G.rime_toggled = false
  else
    _G.rime_toggled = true
  end
end

M.switch_rime_math = switch_rime_math
M.force_toggle_rime = force_toggle_rime

local function toggle_rime_if_in_brackets()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, col)
  local after_cursor = line:sub(col + 1)
  local ts_utils = require("nvim-treesitter.ts_utils")
  local node = ts_utils.get_node_at_cursor()

  -- 添加检查 tex.in_mathzone() 和 tex.in_tikz() 的条件
  if tex.in_mathzone() == true or tex.in_tikz() == true then
    return
  end

  if before_cursor:match("\\%a+%{[^}]*$") then
    if vim.g.rime_enabled and not _G.changed_by_this then
      require("lsp.rime_ls").toggle_rime()
      _G.rime_toggled = false
      _G.rime_ls_active = false
      _G.changed_by_this = true
    end
  end
  if node:type() == "generic_environment" then
    if not vim.g.rime_enabled and _G.changed_by_this then
      require("lsp.rime_ls").toggle_rime()
      _G.rime_toggled = true
      _G.rime_ls_active = true
      _G.changed_by_this = not _G.changed_by_this
    end
  end
end

-- vim.api.nvim_create_autocmd("CursorMovedI", {
--   pattern = "*.tex",
--   callback = toggle_rime_if_in_brackets,
-- })

vim.api.nvim_create_autocmd({ "CursorMovedI" }, {
  pattern = { "*.tex", "*.typ" },
  callback = switch_rime_math,
})

local function switch_rime_math_md()
  if vim.bo.filetype == "markdown" then
    -- in the mathzone or table or tikz and rime is active, disable rime
    if in_math() and rime_ls_active == true then
      if _G.rime_toggled == true then
        require("lsp.rime_ls").toggle_rime()
        _G.rime_toggled = false
      end
      -- in the text but rime is not active(by hand), do nothing
    elseif _G.rime_ls_active == false then
      -- in the text but rime is active(by hand ), thus the configuration is for mathzone or table or tikz
    else
      if _G.rime_toggled == false then
        require("lsp.rime_ls").toggle_rime()
        _G.rime_toggled = true
      end
      if _G.rime_ls_active and _G.rime_toggled then
      end
    end
  end
end

vim.api.nvim_create_autocmd("CursorMovedI", {
  pattern = "*.md",
  callback = switch_rime_math_md,
})

return M
