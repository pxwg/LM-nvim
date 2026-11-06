local M = {}
local saved
local snippet_node
local configured = false

local function typst_region()
  local typst = require("util.typst")
  return typst.in_math() or typst.in_dsl()
end

local function latex_region()
  local tex = require("util.latex")
  return tex.in_mathzone() or tex.in_tikz()
end

-- Snippet ranges handle empty fields; these detectors handle ordinary movement.
M.detectors = {
  org = typst_region,
  typst = typst_region,
  tex = latex_region,
  plaintex = latex_region,
}

local function restore()
  if not saved then
    return
  end
  local previous = saved
  saved = nil
  require("lsp.rime_ls").set_enabled(previous.enabled)
  _G.rime_toggled = previous.toggled
  _G.rime_math = previous.math
end

local function enter()
  if not saved then
    saved = {
      enabled = vim.g.rime_enabled ~= false,
      toggled = _G.rime_toggled,
      math = _G.rime_math,
    }
    require("lsp.rime_ls").set_enabled(false)
    _G.rime_toggled = false
    _G.rime_math = true
  end
end

-- The insert node remains meaningful even when Org parses empty $$ as an error.
local function inside_snippet()
  if not snippet_node or snippet_node.buf ~= vim.api.nvim_get_current_buf() then
    return false
  end
  local ok, first, last = pcall(function()
    return snippet_node.node.mark:pos_begin_end()
  end)
  if not ok then
    snippet_node = nil
    return false
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  return (row > first[1] or row == first[1] and col >= first[2])
    and (row < last[1] or row == last[1] and col <= last[2])
end

function M.update()
  if inside_snippet() then
    enter()
    return
  end
  local detect = M.detectors[vim.bo.filetype]
  if not detect then
    restore()
    return
  end
  local ok, english = pcall(function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local parser = vim.treesitter.get_parser(0)
    if parser then
      parser:parse({ cursor[1] - 1, cursor[1] })
    end
    return detect()
  end)
  if ok and english then
    enter()
  else
    restore()
  end
end

function M.snippet_enter(node)
  M.setup()
  snippet_node = { node = node, buf = vim.api.nvim_get_current_buf() }
  enter()
end

function M.snippet_exit()
  snippet_node = nil
  restore()
end

-- Add to a LuaSnip snippet's opts. Node numbers refer to its direct children.
-- Formula/label snippets can keep both fields English via enter = { 1, 2 }.
function M.callbacks(opts)
  opts = opts or {}
  local events = require("luasnip.util.events")
  local callbacks = {}
  for _, index in ipairs(opts.enter or { 1 }) do
    callbacks[index] = { [events.enter] = M.snippet_enter }
  end
  for _, index in ipairs(opts.exit or { 0 }) do
    callbacks[index] = { [events.enter] = M.snippet_exit }
  end
  return callbacks
end

function M.setup()
  if configured then
    return
  end
  configured = true
  local group = vim.api.nvim_create_augroup("RimeInputRegion", { clear = true })
  vim.api.nvim_create_autocmd(
    { "InsertEnter", "CursorMovedI", "CursorMoved", "TextChangedI", "TextChangedP", "BufEnter" },
    {
      group = group,
      callback = function()
        if saved or M.detectors[vim.bo.filetype] then
          M.update()
        end
      end,
    }
  )
  vim.api.nvim_create_autocmd("LspTokenUpdate", {
    group = group,
    callback = function(event)
      if event.buf == vim.api.nvim_get_current_buf() and vim.bo.filetype == "typst" then
        M.update()
      end
    end,
  })
end

return M
