local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local f = ls.function_node
local c = ls.choice_node
local i = ls.insert_node
local d = ls.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

-- Helper function to check if we're in a Typst file
local function in_typst()
  return vim.bo.filetype == "typst"
end

local function in_math()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, col)
  
  -- Check if we're inside $ ... $ 
  local dollar_before = 0
  for _ in before_cursor:gmatch("%$") do
    dollar_before = dollar_before + 1
  end
  
  return dollar_before % 2 == 1
end

-- Generate matrix content for nxn matrix
local gen_mat = function(ncol, nrow)
  local M = {}
  
  for x = 1, nrow, 1 do
    local N = {}
    table.insert(N, i(1 + (x - 1) * ncol))
    for y = 2, ncol, 1 do
      table.insert(N, t(", "))
      table.insert(N, i(y + (x - 1) * ncol))
    end
    if x < nrow then
      table.insert(N, t({ ";", "  " }))
    end
    
    for _, v in ipairs(N) do
      table.insert(M, v)
    end
  end
  return sn(nil, M)
end

return {
  -- Square matrices (nxn)
  s({
    trig = "mat(%d)",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    t("mat("),
    t({ "", "  " }),
    d(1, function(_, parent)
      local n = tonumber(parent.snippet.captures[1])
      return gen_mat(n, n)
    end, {}),
    t({ "", ")" }),
    i(0),
  }, { condition = in_math }),

  -- Rectangular matrices (nxm)
  s({
    trig = "mat(%d)x(%d)",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    t("mat("),
    t({ "", "  " }),
    d(1, function(_, parent)
      local ncol = tonumber(parent.snippet.captures[1])
      local nrow = tonumber(parent.snippet.captures[2])
      return gen_mat(ncol, nrow)
    end, {}),
    t({ "", ")" }),
    i(0),
  }, { condition = in_math }),

  -- Alternative syntax for rectangular matrices
  s({
    trig = "mat:(%d)(%d)",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    t("mat("),
    t({ "", "  " }),
    d(1, function(_, parent)
      local ncol = tonumber(parent.snippet.captures[1])
      local nrow = tonumber(parent.snippet.captures[2])
      return gen_mat(ncol, nrow)
    end, {}),
    t({ "", ")" }),
    i(0),
  }, { condition = in_math }),

  -- Common matrix sizes with shortcuts
  s({
    trig = "mat2",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("mat("),
    t({ "", "  " }),
    i(1), t(", "), i(2), t({ ";", "  " }),
    i(3), t(", "), i(4),
    t({ "", ")" }),
    i(0),
  }, { condition = in_math }),

  s({
    trig = "mat3",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("mat("),
    t({ "", "  " }),
    i(1), t(", "), i(2), t(", "), i(3), t({ ";", "  " }),
    i(4), t(", "), i(5), t(", "), i(6), t({ ";", "  " }),
    i(7), t(", "), i(8), t(", "), i(9),
    t({ "", ")" }),
    i(0),
  }, { condition = in_math }),

  -- Vector shortcuts
  s({
    trig = "vec(%d)",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    t("vec("),
    d(1, function(_, parent)
      local n = tonumber(parent.snippet.captures[1])
      return gen_mat(1, n)
    end, {}),
    t(")"),
    i(0),
  }, { condition = in_math }),

  s({
    trig = "vec2",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("vec("), i(1), t(", "), i(2), t(")"), i(0),
  }, { condition = in_math }),

  s({
    trig = "vec3",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("vec("), i(1), t(", "), i(2), t(", "), i(3), t(")"), i(0),
  }, { condition = in_math }),

  -- Determinant
  s({
    trig = "detmat(%d)",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    t("det(mat("),
    t({ "", "  " }),
    d(1, function(_, parent)
      local n = tonumber(parent.snippet.captures[1])
      return gen_mat(n, n)
    end, {}),
    t({ "", "))" }),
    i(0),
  }, { condition = in_math }),

  -- Common matrix operations
  s({
    trig = "transpose",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("<>^T<>", { i(1), i(0) }), { condition = in_math }),

  s({
    trig = "inv",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("<>^(-1)<>", { i(1), i(0) }), { condition = in_math }),

  -- Special matrices
  s({
    trig = "imat(%d)",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    f(function(_, snip)
      local n = tonumber(snip.captures[1])
      return "mat(" .. string.rep("1, 0; ", n-1) .. "1)"
    end),
    i(0),
  }, { condition = in_math }),

  -- Zero matrix
  s({
    trig = "zmat(%d)",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    f(function(_, snip)
      local n = tonumber(snip.captures[1])
      return "mat(" .. string.rep("0, ", n-1) .. "0)"
    end),
    i(0),
  }, { condition = in_math }),

  -- Matrix delimiters with choices
  s({
    trig = "pmat(%d)",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    t("lr((mat("),
    t({ "", "  " }),
    d(1, function(_, parent)
      local n = tonumber(parent.snippet.captures[1])
      return gen_mat(n, n)
    end, {}),
    t({ "", ")))" }),
    i(0),
  }, { condition = in_math }),

  s({
    trig = "bmat(%d)",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    t("lr([mat("),
    t({ "", "  " }),
    d(1, function(_, parent)
      local n = tonumber(parent.snippet.captures[1])
      return gen_mat(n, n)
    end, {}),
    t({ "", ")])" }),
    i(0),
  }, { condition = in_math }),

  s({
    trig = "vmat(%d)",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    t("lr(|mat("),
    t({ "", "  " }),
    d(1, function(_, parent)
      local n = tonumber(parent.snippet.captures[1])
      return gen_mat(n, n)
    end, {}),
    t({ "", ")|)" }),
    i(0),
  }, { condition = in_math }),
}

