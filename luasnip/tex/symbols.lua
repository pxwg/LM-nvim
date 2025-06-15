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
    trig = "(%a+)rm", -- Regex for any letter followed by 'arm'
    snippetType = "autosnippet",
    wordTrig = false, -- Allows partial word matches
    regTrig = true, -- Enables regex usage
  }, {
    f(function(_, snip)
      return "\\mathrm{" .. snip.captures[1] .. "}"
    end),
  }, { condition = tex.in_mathzone }),

  s({
    trig = "(%a)cal", -- Regex for any letter followed by 'arm'
    snippetType = "autosnippet",
    wordTrig = false, -- Allows partial word matches
    regTrig = true, -- Enables regex usage
  }, {
    f(function(_, snip)
      return "\\mathcal{" .. snip.captures[1] .. "}"
    end),
  }, { condition = tex.in_mathzone }),

  s({
    trig = "(%a)bf", -- Regex for any letter followed by 'arm'
    snippetType = "autosnippet",
    wordTrig = false, -- Allows partial word matches
    regTrig = true, -- Enables regex usage
  }, {
    f(function(_, snip)
      return "\\mathbf{" .. snip.captures[1] .. "}"
    end),
  }, { condition = tex.in_mathzone }),

  s({
    trig = [[oo]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, t("\\infty "), { condition = tex.in_mathzone }),

  s({
    trig = "rm",
    snippetType = "autosnippet",
    wordTrig = false,
  }, fmta("\\mathrm{<>}<>", { i(1), i(0) }), { condition = tex.in_mathzone }),

  s({
    trig = [[...]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, t("\\cdots "), { condition = tex.in_mathzone }),

  s({
    trig = [[::]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, t("\\colon "), { condition = tex.in_mathzone }),

  s({
    trig = [[+-]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, t("\\pm "), { condition = tex.in_mathzone }),

  s(
    { trig = "xx", wordTrig = true, snippetType = "autosnippet" },
    fmta([[\times <>]], {
      i(1),
    }),
    { condition = tex.in_latex }
  ),
  s({
    trig = [[->]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, t("\\rightarrow "), { condition = tex.in_mathzone }),

  s({
    trig = [[<-]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, t("\\leftarrow "), { condition = tex.in_mathzone }),
  s({
    trig = [[|->]],
    snippetType = "autosnippet",
    wordTrig = false,
    priority = 2000,
  }, t("\\mapsto "), { condition = tex.in_mathzone }),

  s({
    trig = [[~=]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, t("\\cong"), { condition = tex.in_mathzone }),

  s({
    trig = [[QQ]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\mathbb{Q}"), { condition = tex.in_mathzone }),
  s({
    trig = [[RR]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\mathbb{R}"), { condition = tex.in_mathzone }),
  s({
    trig = [[ZZ]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\mathbb{Z}"), { condition = tex.in_mathzone }),
  s({
    trig = [[EE]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\exists "), { condition = tex.in_mathzone }),
  s({
    trig = [[AA]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\forall "), { condition = tex.in_mathzone }),

  s({
    trig = [[inn]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\in "), { condition = tex.in_mathzone }),

  -- 下面是一些等号
  s({
    trig = [[==]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\equiv "), { condition = tex.in_mathzone }),
  s({
    trig = [[!=]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\neq "), { condition = tex.in_mathzone }),
  s({
    trig = [[>=]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\ge "), { condition = tex.in_mathzone }),
  s({
    trig = [[<=]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\le "), { condition = tex.in_mathzone }),

  s({
    trig = [[sim]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\sim "), { condition = tex.in_mathzone }),

  s({
    trig = [[\sim eq]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\simeq "), { condition = tex.in_mathzone }),

  s({
    trig = [[~~]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\approx "), { condition = tex.in_mathzone }),

  -- 下面是不等号
  s({
    trig = [[>>]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, t("\\gg "), { condition = tex.in_mathzone }),
  s({
    trig = [[<<]],
    snippetType = "autosnippet",
    wordTrig = false,
  }, t("\\ll "), { condition = tex.in_mathzone }),

  -- 下面是推导符号
  s({
    trig = [[=>]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\implies "), { condition = tex.in_mathzone }),
  s({
    trig = [[=<]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\impliedby "), { condition = tex.in_mathzone }),
  s({
    trig = [[\le >]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("\\iff "), { condition = tex.in_mathzone }),

  -- 下面是一些环境符号
  s({ trig = [[oo]], snippetType = "autosnippet", wordTrig = false }, t("\\item "), { condition = tex.in_item }),

  -- section
  s({
    trig = [[secs]],
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("\\section{<>}", { i(0) }), { condition = tex.in_text }),
  s({
    trig = [[ssecs]],
    snippetType = "autosnippet",
    wordTrig = true,
    priority = 2000,
  }, fmta("\\subsection{<>}", { i(0) }), { condition = tex.in_text }),
}
