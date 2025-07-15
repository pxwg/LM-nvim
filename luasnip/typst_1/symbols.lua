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

return {
  -- Greek letters (lowercase)
  s({ trig = "alpha", snippetType = "autosnippet", wordTrig = true }, t("alpha"), { condition = in_math }),
  s({ trig = "beta", snippetType = "autosnippet", wordTrig = true }, t("beta"), { condition = in_math }),
  s({ trig = "gamma", snippetType = "autosnippet", wordTrig = true }, t("gamma"), { condition = in_math }),
  s({ trig = "delta", snippetType = "autosnippet", wordTrig = true }, t("delta"), { condition = in_math }),
  s({ trig = "epsilon", snippetType = "autosnippet", wordTrig = true }, t("epsilon"), { condition = in_math }),
  s({ trig = "zeta", snippetType = "autosnippet", wordTrig = true }, t("zeta"), { condition = in_math }),
  s({ trig = "eta", snippetType = "autosnippet", wordTrig = true }, t("eta"), { condition = in_math }),
  s({ trig = "theta", snippetType = "autosnippet", wordTrig = true }, t("theta"), { condition = in_math }),
  s({ trig = "iota", snippetType = "autosnippet", wordTrig = true }, t("iota"), { condition = in_math }),
  s({ trig = "kappa", snippetType = "autosnippet", wordTrig = true }, t("kappa"), { condition = in_math }),
  s({ trig = "lambda", snippetType = "autosnippet", wordTrig = true }, t("lambda"), { condition = in_math }),
  s({ trig = "mu", snippetType = "autosnippet", wordTrig = true }, t("mu"), { condition = in_math }),
  s({ trig = "nu", snippetType = "autosnippet", wordTrig = true }, t("nu"), { condition = in_math }),
  s({ trig = "xi", snippetType = "autosnippet", wordTrig = true }, t("xi"), { condition = in_math }),
  s({ trig = "pi", snippetType = "autosnippet", wordTrig = true }, t("pi"), { condition = in_math }),
  s({ trig = "rho", snippetType = "autosnippet", wordTrig = true }, t("rho"), { condition = in_math }),
  s({ trig = "sigma", snippetType = "autosnippet", wordTrig = true }, t("sigma"), { condition = in_math }),
  s({ trig = "tau", snippetType = "autosnippet", wordTrig = true }, t("tau"), { condition = in_math }),
  s({ trig = "upsilon", snippetType = "autosnippet", wordTrig = true }, t("upsilon"), { condition = in_math }),
  s({ trig = "phi", snippetType = "autosnippet", wordTrig = true }, t("phi"), { condition = in_math }),
  s({ trig = "chi", snippetType = "autosnippet", wordTrig = true }, t("chi"), { condition = in_math }),
  s({ trig = "psi", snippetType = "autosnippet", wordTrig = true }, t("psi"), { condition = in_math }),
  s({ trig = "omega", snippetType = "autosnippet", wordTrig = true }, t("omega"), { condition = in_math }),

  -- Greek letters (uppercase)
  s({ trig = "Alpha", snippetType = "autosnippet", wordTrig = true }, t("Alpha"), { condition = in_math }),
  s({ trig = "Beta", snippetType = "autosnippet", wordTrig = true }, t("Beta"), { condition = in_math }),
  s({ trig = "Gamma", snippetType = "autosnippet", wordTrig = true }, t("Gamma"), { condition = in_math }),
  s({ trig = "Delta", snippetType = "autosnippet", wordTrig = true }, t("Delta"), { condition = in_math }),
  s({ trig = "Epsilon", snippetType = "autosnippet", wordTrig = true }, t("Epsilon"), { condition = in_math }),
  s({ trig = "Zeta", snippetType = "autosnippet", wordTrig = true }, t("Zeta"), { condition = in_math }),
  s({ trig = "Eta", snippetType = "autosnippet", wordTrig = true }, t("Eta"), { condition = in_math }),
  s({ trig = "Theta", snippetType = "autosnippet", wordTrig = true }, t("Theta"), { condition = in_math }),
  s({ trig = "Iota", snippetType = "autosnippet", wordTrig = true }, t("Iota"), { condition = in_math }),
  s({ trig = "Kappa", snippetType = "autosnippet", wordTrig = true }, t("Kappa"), { condition = in_math }),
  s({ trig = "Lambda", snippetType = "autosnippet", wordTrig = true }, t("Lambda"), { condition = in_math }),
  s({ trig = "Mu", snippetType = "autosnippet", wordTrig = true }, t("Mu"), { condition = in_math }),
  s({ trig = "Nu", snippetType = "autosnippet", wordTrig = true }, t("Nu"), { condition = in_math }),
  s({ trig = "Xi", snippetType = "autosnippet", wordTrig = true }, t("Xi"), { condition = in_math }),
  s({ trig = "Pi", snippetType = "autosnippet", wordTrig = true }, t("Pi"), { condition = in_math }),
  s({ trig = "Rho", snippetType = "autosnippet", wordTrig = true }, t("Rho"), { condition = in_math }),
  s({ trig = "Sigma", snippetType = "autosnippet", wordTrig = true }, t("Sigma"), { condition = in_math }),
  s({ trig = "Tau", snippetType = "autosnippet", wordTrig = true }, t("Tau"), { condition = in_math }),
  s({ trig = "Upsilon", snippetType = "autosnippet", wordTrig = true }, t("Upsilon"), { condition = in_math }),
  s({ trig = "Phi", snippetType = "autosnippet", wordTrig = true }, t("Phi"), { condition = in_math }),
  s({ trig = "Chi", snippetType = "autosnippet", wordTrig = true }, t("Chi"), { condition = in_math }),
  s({ trig = "Psi", snippetType = "autosnippet", wordTrig = true }, t("Psi"), { condition = in_math }),
  s({ trig = "Omega", snippetType = "autosnippet", wordTrig = true }, t("Omega"), { condition = in_math }),

  -- Mathematical operators and symbols
  s({ trig = "oo", snippetType = "autosnippet", wordTrig = false }, t("infinity"), { condition = in_math }),
  s({ trig = "...", snippetType = "autosnippet", wordTrig = false }, t("dots.c"), { condition = in_math }),
  s({ trig = "::", snippetType = "autosnippet", wordTrig = false }, t(":"), { condition = in_math }),
  s({ trig = "+-", snippetType = "autosnippet", wordTrig = false }, t("plus.minus"), { condition = in_math }),
  s({ trig = "xx", snippetType = "autosnippet", wordTrig = true }, t("times"), { condition = in_math }),

  -- Arrows
  s({ trig = "->", snippetType = "autosnippet", wordTrig = false }, t("arrow.r"), { condition = in_math }),
  s({ trig = "<-", snippetType = "autosnippet", wordTrig = false }, t("arrow.l"), { condition = in_math }),
  s(
    { trig = "|->", snippetType = "autosnippet", wordTrig = false, priority = 2000 },
    t("arrow.r.bar"),
    { condition = in_math }
  ),

  -- Relations
  s({ trig = "~=", snippetType = "autosnippet", wordTrig = false }, t("tilde.eq"), { condition = in_math }),
  s({ trig = "==", snippetType = "autosnippet", wordTrig = true }, t("equiv"), { condition = in_math }),
  s({ trig = "!=", snippetType = "autosnippet", wordTrig = true }, t("eq.not"), { condition = in_math }),
  s({ trig = ">=", snippetType = "autosnippet", wordTrig = true }, t("gt.eq"), { condition = in_math }),
  s({ trig = "<=", snippetType = "autosnippet", wordTrig = true }, t("lt.eq"), { condition = in_math }),
  s({ trig = ">>", snippetType = "autosnippet", wordTrig = false }, t(">>"), { condition = in_math }),
  s({ trig = "<<", snippetType = "autosnippet", wordTrig = false }, t("<<"), { condition = in_math }),
  s({ trig = "~~", snippetType = "autosnippet", wordTrig = true }, t("approx"), { condition = in_math }),
  s({ trig = "sim", snippetType = "autosnippet", wordTrig = true }, t("tilde"), { condition = in_math }),

  -- Logic
  s({ trig = "=>", snippetType = "autosnippet", wordTrig = true }, t("arrow.r.double"), { condition = in_math }),
  s({ trig = "=<", snippetType = "autosnippet", wordTrig = true }, t("arrow.l.double"), { condition = in_math }),
  s({ trig = "iff", snippetType = "autosnippet", wordTrig = true }, t("arrow.l.r.double"), { condition = in_math }),

  -- Set theory
  s({ trig = "inn", snippetType = "autosnippet", wordTrig = true }, t("in"), { condition = in_math }),
  s({ trig = "EE", snippetType = "autosnippet", wordTrig = true }, t("exists"), { condition = in_math }),
  s({ trig = "AA", snippetType = "autosnippet", wordTrig = true }, t("forall"), { condition = in_math }),

  -- Number sets
  s({ trig = "RR", snippetType = "autosnippet", wordTrig = true }, t("RR"), { condition = in_math }),
  s({ trig = "QQ", snippetType = "autosnippet", wordTrig = true }, t("QQ"), { condition = in_math }),
  s({ trig = "ZZ", snippetType = "autosnippet", wordTrig = true }, t("ZZ"), { condition = in_math }),
  s({ trig = "NN", snippetType = "autosnippet", wordTrig = true }, t("NN"), { condition = in_math }),
  s({ trig = "CC", snippetType = "autosnippet", wordTrig = true }, t("CC"), { condition = in_math }),

  -- Functions
  s({ trig = "sin", snippetType = "autosnippet", wordTrig = true }, t("sin"), { condition = in_math }),
  s({ trig = "cos", snippetType = "autosnippet", wordTrig = true }, t("cos"), { condition = in_math }),
  s({ trig = "tan", snippetType = "autosnippet", wordTrig = true }, t("tan"), { condition = in_math }),
  s({ trig = "ln", snippetType = "autosnippet", wordTrig = true }, t("ln"), { condition = in_math }),
  s({ trig = "log", snippetType = "autosnippet", wordTrig = true }, t("log"), { condition = in_math }),
  s({ trig = "exp", snippetType = "autosnippet", wordTrig = true }, t("exp"), { condition = in_math }),
  s({ trig = "det", snippetType = "autosnippet", wordTrig = true }, t("det"), { condition = in_math }),

  -- Special constants
  s(
    { trig = "ee", snippetType = "autosnippet", wordTrig = true },
    fmta("e^(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s({ trig = "ii", snippetType = "autosnippet", wordTrig = true }, t("i"), { condition = in_math }),

  -- Brackets and parentheses shortcuts
  s(
    { trig = "lr(", snippetType = "autosnippet", wordTrig = false },
    fmta("lr((<>))<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "lr[", snippetType = "autosnippet", wordTrig = false },
    fmta("lr([<>])<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "lr{", snippetType = "autosnippet", wordTrig = false },
    fmta("lr({{<>}})<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "lr|", snippetType = "autosnippet", wordTrig = false },
    fmta("lr(|<>|)<>", { i(1), i(0) }),
    { condition = in_math }
  ),

  -- Derivatives
  s({ trig = "dif", snippetType = "autosnippet", wordTrig = true }, t("dif"), { condition = in_math }),
  s({ trig = "dd", snippetType = "autosnippet", wordTrig = true }, t("dd"), { condition = in_math }),

  -- Accents and decorations
  s(
    { trig = "hat", snippetType = "autosnippet", wordTrig = false },
    fmta("hat(<>)<>", { i(1), i(0) }),
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
  s(
    { trig = "dot", snippetType = "autosnippet", wordTrig = false },
    fmta("dot(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),
  s(
    { trig = "ddot", snippetType = "autosnippet", wordTrig = false },
    fmta("dot.double(<>)<>", { i(1), i(0) }),
    { condition = in_math }
  ),
}
