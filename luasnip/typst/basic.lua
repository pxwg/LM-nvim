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
local line_begin = require("luasnip.extras.expand_conditions").line_begin
local cn = require("util.math_autochange")
local typst = require("util.typst")

-- Helper function to check if we're in a Typst file
local function in_typst()
  return vim.bo.filetype == "typst"
end

local function in_math()
  return typst.in_math()
end

return {
  -- Inline math
  s(
    { trig = "km", wordTrig = true, snippetType = "autosnippet" },
    { t("$ "), i(1), t("$"), i(0) },
    { condition = in_typst }
  ),
  s(
    { trig = "mk", wordTrig = true, snippetType = "autosnippet" },
    { t("$ "), i(1), t("$"), i(0) },
    { condition = in_typst }
  ),

  -- Display math (unnumbered)
  s(
    { trig = "eqs", snippetType = "autosnippet" },
    fmta(
      [[
        $
          <>
        $ <>
      ]],
      { i(1), i(0) }
    ),
    { condition = line_begin }
  ),

  -- Display math (numbered)
  s(
    { trig = "eqt", snippetType = "autosnippet" },
    fmta(
      [[
        $ <> $ <<label(<>)>><>
      ]],
      { i(1), i(2, "eq:"), i(0) }
    ),
    { condition = line_begin }
  ),

  -- Subscripts
  s(
    { trig = "td", wordTrig = false, snippetType = "autosnippet" },
    { t("_("), i(1), t(")"), i(0) },
    { condition = in_math }
  ),

  -- Superscripts
  s(
    { trig = "tp", wordTrig = false, snippetType = "autosnippet" },
    { t("^("), i(1, "2"), t(")"), i(0) },
    { condition = in_math }
  ),

  -- Auto subscripts for single characters
  s(
    { trig = "([%a%)])(%d)", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>_<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      f(function(_, snip)
        return snip.captures[2]
      end),
    }),
    { condition = in_math }
  ),

  -- Auto subscripts for multiple digits
  s(
    { trig = "([%a%)])_(%d)(%d)", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>_(<><>)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      f(function(_, snip)
        return snip.captures[2]
      end),
      f(function(_, snip)
        return snip.captures[3]
      end),
    }),
    { condition = in_math }
  ),

  -- Simple fractions
  s(
    { trig = "//", wordTrig = true, snippetType = "autosnippet", priority = 100 },
    fmta("frac(<>, <>)<>", {
      i(1),
      i(2),
      i(0),
    }),
    { condition = in_math }
  ),

  -- Fraction with number capture
  s(
    { trig = "(%d+)/", regTrig = true, wordTrig = false, snippetType = "autosnippet", priority = 100 },
    fmta("frac(<>, <>)<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(1),
      i(0),
    }),
    { condition = in_math }
  ),

  -- Fraction with letter capture
  s(
    { trig = "(%a)/", regTrig = true, wordTrig = false, snippetType = "autosnippet", priority = 100 },
    fmta("frac(<>, <>)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(1),
    }),
    { condition = in_math }
  ),

  -- Fraction with parentheses capture
  s(
    { trig = "%((.+)%)/", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("frac(<>, <>)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(1),
    }),
    { condition = in_math }
  ),

  -- Sum with limits
  s(
    { trig = "sum", snippetType = "autosnippet" },
    c(1, {
      sn(nil, { t("sum_("), i(1), t(")^("), i(2), t(") ") }),
      sn(nil, { t("sum_("), i(1), t(") ") }),
      sn(nil, { t("sum "), i(1) }),
    }),
    { condition = in_math }
  ),

  -- Product with limits
  s(
    { trig = "prod", snippetType = "autosnippet" },
    c(1, {
      sn(nil, { t("product_("), i(1), t(")^("), i(2), t(") ") }),
      sn(nil, { t("product_("), i(1), t(") ") }),
      sn(nil, { t("product "), i(1) }),
    }),
    { condition = in_math }
  ),

  -- Limit
  s(
    { trig = "lim", snippetType = "autosnippet" },
    c(1, {
      sn(nil, { t("lim "), i(1) }),
      sn(nil, { t("lim_("), i(1, "x"), t(" -> "), i(2, "infinity"), t(") "), i(0) }),
    }),
    { condition = in_math }
  ),

  -- Integral
  s(
    { trig = "int", snippetType = "autosnippet" },
    c(1, {
      sn(nil, {
        t("integral_("),
        i(1, "-infinity"),
        t(")^("),
        i(2, "infinity"),
        t(") "),
        i(3),
        t(" dif "),
        i(4, "x"),
        t(" "),
        i(0),
      }),
      sn(nil, { t("integral "), i(1), t(" dif "), i(2, "x"), t(" "), i(0) }),
    }),
    { condition = in_math }
  ),

  -- nth root
  s(
    { trig = "([2-9])sq", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("root(<>, <>)<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(1),
      i(0),
    }),
    { condition = in_math }
  ),
}
