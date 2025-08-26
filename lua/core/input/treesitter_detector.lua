-- Unified treesitter-based environment detection for input method switching
-- Consolidates logic from lua/util/latex.lua and lua/util/math_autochange.lua

local M = {}

local ts_utils = require("nvim-treesitter.ts_utils")

-- Math-related node types that should disable rime_ls
local MATH_NODES = {
  displayed_equation = true,
  inline_formula = true,
  math_environment = true,
}

-- Environment detection for LaTeX via treesitter
function M.in_latex_env(env_name)
  local node = ts_utils.get_node_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  
  while node do
    if node:type() == "generic_environment" then
      local begin = node:child(0)
      local name = begin:field("name")
      if name[1] and vim.treesitter.get_node_text(name[1], bufnr, nil) == "{" .. env_name .. "}" then
        return true
      end
    end
    node = node:parent()
  end
  return false
end

-- Check if cursor is in text mode (not in math)
function M.in_text_mode()
  local node = ts_utils.get_node_at_cursor()
  
  while node do
    if node:type() == "text_mode" then
      return true
    elseif MATH_NODES[node:type()] then
      return false
    end
    node = node:parent()
  end
  return true
end

-- Check if cursor is in math zone
function M.in_math_zone()
  return not M.in_text_mode()
end

-- Specific environment checkers
function M.in_tikz()
  return M.in_latex_env("tikzpicture")
end

function M.in_table()
  return M.in_latex_env("xltabular")
end

function M.in_itemize()
  return M.in_latex_env("itemize") or M.in_latex_env("enumerate")
end

function M.in_figure()
  return M.in_latex_env("figure")
end

function M.in_center()
  return M.in_latex_env("center")
end

-- Check for LaTeX command brackets (for disabling rime in command parameters)
function M.in_latex_command_brackets()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, col)
  
  -- Check if cursor is inside LaTeX command brackets
  return before_cursor:match("\\%a+%{[^}]*$") ~= nil
end

-- Typst math detection (if available)
function M.in_typst_math()
  -- Try to load typst utility if it exists
  local success, typst = pcall(require, "util.typst")
  if success and typst.in_math then
    return typst.in_math()
  end
  return false
end

-- Universal math detection across file types
function M.in_math_environment()
  local filetype = vim.bo.filetype
  
  if filetype == "tex" or filetype == "plaintex" then
    return M.in_math_zone() or M.in_tikz()
  elseif filetype == "typst" then
    return M.in_typst_math()
  elseif filetype == "markdown" then
    -- For markdown, check for math blocks/inline math
    return M.in_math_zone()
  end
  
  return false
end

-- Check if rime should be disabled based on current context
function M.should_disable_rime()
  local filetype = vim.bo.filetype
  
  -- Only apply to supported file types
  if not (filetype == "tex" or filetype == "plaintex" or filetype == "typst" or filetype == "markdown") then
    return false
  end
  
  -- Disable rime in math environments or TikZ
  if M.in_math_environment() then
    return true
  end
  
  -- For LaTeX files, also disable in command brackets
  if (filetype == "tex" or filetype == "plaintex") and M.in_latex_command_brackets() then
    return true
  end
  
  return false
end

-- Get current environment context for debugging
function M.get_context()
  local filetype = vim.bo.filetype
  local node = ts_utils.get_node_at_cursor()
  
  return {
    filetype = filetype,
    node_type = node and node:type() or "none",
    in_text = M.in_text_mode(),
    in_math = M.in_math_zone(),
    in_tikz = M.in_tikz(),
    in_command_brackets = M.in_latex_command_brackets(),
    should_disable_rime = M.should_disable_rime(),
  }
end

return M