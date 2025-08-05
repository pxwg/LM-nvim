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
local typst = require("util.typst")

return {
  s({
    trig = [[@|]],
    snippetType = "autosnippet",
    wordTrig = false,
    trigEngine = "ecma",
  }, {
    t("| "),
    i(1),
    t(" | "),
    i(0),
  }, { condition = typst.in_math }),

  s({
    trig = [[@>]],
    snippetType = "autosnippet",
    wordTrig = false,
    trigEngine = "ecma",
  }, {
    t("angle.l "),
    i(1),
    t(" angle.r "),
    i(0),
  }, { condition = typst.in_math }),

  s({
    trig = "set",
    snippetType = "autosnippet",
    wordTrig = true,
  }, {
    t("\\{ "),
    i(1),
    t(" \\}"),
    i(0),
  }, { condition = typst.in_math }),

  s({
    trig = [[bra]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, {
    t("bra("),
    i(1),
    t(")"),
    i(0),
  }, { condition = typst.in_math }),

  s({
    trig = [[ket]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, {
    t("ket("),
    i(1),
    t(")"),
    i(0),
  }, { condition = typst.in_math }),
}
