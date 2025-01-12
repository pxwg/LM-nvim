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
local tex = require("util.latex")

return {
  s({
    trig = "(?<!\\)(hbar|dagger|quad|qquad|to|max|min|sup|inf|mod)",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
    priority = 1500,
  }, {
    f(function(_, snip)
      return "\\" .. snip.captures[1] .. " "
    end),
  }, { condition = tex.in_latex }),

  s({
    trig = [[2pi]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, t("2\\pi "), { condition = tex.in_latex }),
  s({
    trig = [[(?<!\\)\b([a-zA-Z]+)opn]],
    snippetType = "autosnippet",
    wordTrig = false,
    trigEngine = "ecma",
    priority = 1500,
  }, {
    f(function(_, snip)
      return "\\operatorname{" .. snip.captures[1] .. "}"
    end),
  }, { condition = tex.in_latex }),

  -- s({
  --   trig = [[(?<!\\)(mu|alpha|sigma|rho|beta|Beta|gamma|delta|pi|zeta|eta|varepsilon|theta|iota|kappa|vartheta|lambda|xi|nu|pi|rho|tau|upsilon|varphi|phi|chi|psi|omega|Gamma|Delta|Theta|Lambda|Xi|Pi|Sigma|Upsilon|Phi|Psi|Omega)]],
  --   snippetType = "autosnippet",
  --   wordTrig = true,
  --   trigEngine = "ecma",
  -- }, {
  --   f(function(_, snip)
  --     return "\\" .. snip.captures[1] .. " "
  --   end),
  -- }, { condition = tex.in_latex }),

  s({
    trig = "mu",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\mu"), { condition = tex.in_latex }),

  s({
    trig = "alpha",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\alpha"), { condition = tex.in_latex }),

  s({
    trig = "sigma",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\sigma"), { condition = tex.in_latex }),

  s({
    trig = "rho",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\rho"), { condition = tex.in_latex }),

  s({
    trig = "beta",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\beta"), { condition = tex.in_latex }),

  s({
    trig = "Beta",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Beta"), { condition = tex.in_latex }),

  s({
    trig = "gamma",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\gamma"), { condition = tex.in_latex }),

  s({
    trig = "delta",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\delta"), { condition = tex.in_latex }),

  s({
    trig = "pi",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\pi"), { condition = tex.in_latex }),

  s({
    trig = "zeta",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\zeta"), { condition = tex.in_latex }),

  s({
    trig = "eta",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\eta"), { condition = tex.in_latex }),

  s({
    trig = "varepsilon",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\varepsilon"), { condition = tex.in_latex }),

  s({
    trig = "theta",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\theta"), { condition = tex.in_latex }),

  s({
    trig = "iota",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\iota"), { condition = tex.in_latex }),

  s({
    trig = "kappa",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\kappa"), { condition = tex.in_latex }),

  s({
    trig = "vartheta",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\vartheta"), { condition = tex.in_latex }),

  s({
    trig = "lambda",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\lambda"), { condition = tex.in_latex }),

  s({
    trig = "xi",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\xi"), { condition = tex.in_latex }),

  s({
    trig = "nu",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\nu"), { condition = tex.in_latex }),

  s({
    trig = "tau",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\tau"), { condition = tex.in_latex }),

  s({
    trig = "upsilon",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\upsilon"), { condition = tex.in_latex }),

  s({
    trig = "varphi",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\varphi"), { condition = tex.in_latex }),

  s({
    trig = "phi",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\phi"), { condition = tex.in_latex }),

  s({
    trig = "chi",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\chi"), { condition = tex.in_latex }),

  s({
    trig = "psi",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\psi"), { condition = tex.in_latex }),

  s({
    trig = "omega",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\omega"), { condition = tex.in_latex }),

  s({
    trig = "Gamma",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Gamma"), { condition = tex.in_latex }),

  s({
    trig = "Delta",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Delta"), { condition = tex.in_latex }),

  s({
    trig = "Theta",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Theta"), { condition = tex.in_latex }),

  s({
    trig = "Lambda",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Lambda"), { condition = tex.in_latex }),

  s({
    trig = "Xi",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Xi"), { condition = tex.in_latex }),

  s({
    trig = "Pi",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Pi"), { condition = tex.in_latex }),

  s({
    trig = "Sigma",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Sigma"), { condition = tex.in_latex }),

  s({
    trig = "Upsilon",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Upsilon"), { condition = tex.in_latex }),

  s({
    trig = "Phi",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Phi"), { condition = tex.in_latex }),

  s({
    trig = "Psi",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Psi"), { condition = tex.in_latex }),

  s({
    trig = "Omega",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "ecma",
  }, t("\\Omega"), { condition = tex.in_latex }),

  -- s({
  --   trig = [[(?<!\\)(sin|cos|tan|arccot|cot|csc|ln|exp|det|arcsin|arccos|arctan|arccot|arccsc|arcsec|nabla|int)]],
  --   snippetType = "autosnippet",
  --   wordTrig = true,
  --   trigEngine = "ecma",
  -- }, {
  --   f(function(_, snip)
  --     return "\\" .. snip.captures[1] .. " "
  --   end),
  -- }, { condition = tex.in_latex }),

  s({
    trig = "sin",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\sin "),
  }, { condition = tex.in_latex }),

  s({
    trig = "cos",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\cos "),
  }, { condition = tex.in_latex }),

  s({
    trig = "tan",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\tan "),
  }, { condition = tex.in_latex }),

  s({
    trig = "arccot",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\arccot "),
  }, { condition = tex.in_latex }),

  s({
    trig = "cot",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\cot "),
  }, { condition = tex.in_latex }),

  s({
    trig = "csc",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\csc "),
  }, { condition = tex.in_latex }),

  s({
    trig = "ln",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\ln "),
  }, { condition = tex.in_latex }),

  s({
    trig = "exp",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\exp "),
  }, { condition = tex.in_latex }),

  s({
    trig = "det",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\det "),
  }, { condition = tex.in_latex }),

  s({
    trig = "arcsin",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\arcsin "),
  }, { condition = tex.in_latex }),

  s({
    trig = "arccos",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\arccos "),
  }, { condition = tex.in_latex }),

  s({
    trig = "arctan",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\arctan "),
  }, { condition = tex.in_latex }),

  s({
    trig = "arccot",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\arccot "),
  }, { condition = tex.in_latex }),

  s({
    trig = "arccsc",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\arccsc "),
  }, { condition = tex.in_latex }),

  s({
    trig = "arcsec",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\arcsec "),
  }, { condition = tex.in_latex }),

  s({
    trig = "nabla",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\nabla "),
  }, { condition = tex.in_latex }),

  s({
    trig = "int",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\int "),
  }, { condition = tex.in_latex }),
  s({
    trig = "dis",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\displaystyle jj"),
  }, { condition = tex.in_latex }),

  s({
    trig = "ee",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\mathrm{e}^{"),
    i(1),
    t("}"),
    i(0),
  }, { condition = tex.in_latex }),
  s({
    trig = "ii",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\mathrm{i}"),
  }, { condition = tex.in_latex }),

  -- s({
  --   trig = "sb",
  --   snippetType = "autosnippet",
  --   wordTrig = true,
  -- }, {
  --   t("\\mathrm{i}"),
  -- }, { condition = tex.in_latex }),
}
