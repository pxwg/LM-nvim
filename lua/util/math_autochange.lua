local M = {}
local tex = require("util.latex")
local typst = require("util.typst")

-- ==========================================
-- 1. 共用工具函数
-- ==========================================

-- 共用的数学环境判断
local function in_math()
  return tex.in_mathzone() or typst.in_math()
end

-- 共用的防抖函数
local timer = vim.loop.new_timer()
local function debounce(fn, ms)
  return function(...)
    local args = { ... }
    timer:stop()
    timer:start(ms, 0, function()
      vim.schedule(function()
        fn(unpack(args))
      end)
    end)
  end
end

-- ==========================================
-- 2. VSCode + Macism 专属逻辑 (Patch 部分)
-- ==========================================
if vim.g.vscode then
  local im_select_path = "/opt/homebrew/bin/macism"
  local en_im = "com.apple.keylayout.ABC"
  local zh_im = "im.rime.inputmethod.Squirrel"

  local function switch_im(im_code)
    vim.fn.jobstart({ im_select_path, im_code }, { detach = true })
  end

  local was_in_math = false

  -- VSCode 下检查数学环境的执行器
  local function vscode_check_math_im()
    -- 结合 in_math 和原脚本中特有的 in_tikz 检查
    local currently_in_math = in_math()
    if vim.bo.filetype == "tex" and tex.in_tikz() then
      currently_in_math = true
    end

    if currently_in_math and not was_in_math then
      switch_im(en_im)
      was_in_math = true
    elseif not currently_in_math and was_in_math then
      switch_im(zh_im)
      was_in_math = false
    end
  end

  local im_augroup = vim.api.nvim_create_augroup("VSCodeMacismMath", { clear = true })

  -- 插入模式下的移动：套用你原来的 debounce 防抖，防止高速移动光标时狂发 jobstart
  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = im_augroup,
    pattern = { "*.tex", "*.typ", "*.md" },
    callback = debounce(vscode_check_math_im, 100), -- 100ms 防抖
  })

  -- 离开插入模式：全局强制切回英文，重置状态
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = im_augroup,
    pattern = "*",
    callback = function()
      was_in_math = false
      switch_im(en_im)
    end,
  })

  -- 进入插入模式：全局判断初始落点
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = im_augroup,
    pattern = "*",
    callback = function()
      local currently_in_math = in_math()
      if vim.bo.filetype == "tex" and tex.in_tikz() then
        currently_in_math = true
      end

      if currently_in_math then
        was_in_math = true
        switch_im(en_im)
      else
        was_in_math = false
        switch_im(zh_im)
      end
    end,
  })

  -- 占位暴露的方法，防止外部脚本调用报错
  M.switch_rime_math = function() end
  M.force_toggle_rime = function() end

  -- 在这里直接阻断执行，防止加载原生 rime_ls 逻辑
  return M
end

-- ==========================================
-- 3. 原生 Neovim + rime_ls 逻辑 (你原来的代码)
-- ==========================================

_G.rime_toggled = true
_G.rime_ls_active = true
_G.rime_math = false

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

vim.api.nvim_create_autocmd({ "CursorMovedI" }, {
  pattern = { "*.tex", "*.typ" },
  callback = debounce(switch_rime_math, 200),
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
  callback = debounce(switch_rime_math_md, 200),
})

return M
