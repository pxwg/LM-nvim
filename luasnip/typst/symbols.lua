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
local typst = require("util.typst")

local function in_math()
  return typst.in_math()
end

return {
  -- Special constants
  s(
    { trig = "ee", snippetType = "autosnippet", wordTrig = true },
    fmta("e^(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s({ trig = "ii", snippetType = "autosnippet", wordTrig = true }, t("i"), { condition = in_math }),

  -- Brackets and parentheses shortcuts
  s(
    { trig = "@(", snippetType = "autosnippet", wordTrig = false },
    fmta("(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "@[", snippetType = "autosnippet", wordTrig = false },
    fmta("[<>]<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "@{", snippetType = "autosnippet", wordTrig = false },
    fmta("{{<>}}<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "@|", snippetType = "autosnippet", wordTrig = false },
    fmta("|<>|<>", { i(1), i(0) }),
    { condition = in_math }
  ),

  -- Derivatives
  s({ trig = "dd", snippetType = "autosnippet", wordTrig = true }, t("dif"), { condition = in_math }),

  -- Accents and decorations
  s(
    { trig = "hat", snippetType = "autosnippet", wordTrig = false },
    fmta("hat(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "hbar", snippetType = "autosnippet", wordTrig = true, priority = 1005 },
    t("planck.reduce "),
    { condition = in_math }
  ),
  s(
    { trig = "bar", snippetType = "autosnippet", wordTrig = false },
    fmta("overline(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "tilde", snippetType = "autosnippet", wordTrig = false },
    fmta("tilde(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "vec", snippetType = "autosnippet", wordTrig = false },
    fmta("arrow(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s({
    trig = "(%a+)dot",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
    priority = 1000,
  }, {
    f(function(_, snip)
      return "dot(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  s({
    trig = "(%a+)ddot",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
    priority = 10000,
  }, {
    f(function(_, snip)
      return "dot.double(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),
  s(
    { trig = "dot", snippetType = "autosnippet", wordTrig = false },
    fmta("dot(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "ddot", snippetType = "autosnippet", wordTrig = false, priority = 100 },
    fmta("dot.double(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),

  -- Tensor products
  s({ trig = "oxx", snippetType = "autosnippet", wordTrig = false }, t("times.circle"), { condition = in_math }),
  s({ trig = "xx", snippetType = "autosnippet", wordTrig = false }, t("times"), { condition = in_math }),

  -- Intersection and union
  s({ trig = "cup", snippetType = "autosnippet", wordTrig = false }, t("inter"), { condition = in_math }),
  s({ trig = "cap", snippetType = "autosnippet", wordTrig = false }, t("union"), { condition = in_math }),
}
