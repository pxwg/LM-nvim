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
local get_visual = function(args, parent)
  if #parent.snippet.env.SELECT_RAW > 0 then
    return sn(nil, t(parent.snippet.env.SELECT_RAW))
  else -- If SELECT_RAW is empty, return a blank insert node
    return sn(nil, i(1))
  end
end
local gen_mat = function(ncol, nrow)
  local M = {}

  for x = 1, nrow, 1 do
    local N = {}
    table.insert(N, i(1 + (x - 1) * ncol))
    for y = 2, ncol, 1 do
      table.insert(N, t(" & "))
      table.insert(N, i(y + (x - 1) * ncol))
    end
    table.insert(N, t({ "\\\\", "" }))

    for _, v in ipairs(N) do
      table.insert(M, v)
    end
  end
  return sn(nil, M)
end

return {
  s({
    trig = "txt",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "pattern",
    priority = 1500,
  }, { t("\\text{"), f(get_visual), i(1), t("}"), i(0) }, { condition = tex.in_mathzone }),

  s({
    trig = "tbf",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "pattern",
    priority = 1500,
  }, { t("\\textbf{"), f(get_visual), i(1), t("}"), i(0) }, { condition = not tex.in_mathzone }),
  s(
    {
      trig = "(%a+)cal",
      snippetType = "autosnippet",
      wordTrig = true,
      trigEngine = "pattern",
    },
    { f(function(_, snip)
      return "\\mathcal{" .. string.upper(snip.captures[1]) .. "}"
    end) },
    { condition = tex.in_mathzone }
  ),

  s(
    {
      trig = "([A-Z]+)bb",
      snippetType = "autosnippet",
      wordTrig = true,
      trigEngine = "pattern",
    },
    { f(function(_, snip)
      return "\\mathbb{" .. string.upper(snip.captures[1]) .. "}"
    end) },
    { condition = tex.in_mathzone }
  ),

  s(
    {
      trig = "(%a+)scr",
      snippetType = "autosnippet",
      wordTrig = true,
      trigEngine = "pattern",
    },
    { f(function(_, snip)
      return "\\mathscr{" .. snip.captures[1] .. "}"
    end), i(0) },
    { condition = tex.in_mathzone }
  ),

  s(
    {
      trig = "(%a+)frk",
      snippetType = "autosnippet",
      wordTrig = true,
      trigEngine = "pattern",
    },
    { f(function(_, snip)
      return "\\mathfrak{" .. snip.captures[1] .. "}"
    end), i(0) },
    { condition = tex.in_mathzone }
  ),

  s({
    trig = "(%A+)bb",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "pattern",
    priority = 3000,
  }, { f(function(_, snip)
    return "\\mathbb{" .. snip.captures[1] .. "}"
  end) }, { condition = tex.in_mathzone }),

  s(
    { trig = "tbf", snippetType = "autosnippet", priority = 2000 },
    fmta("\\textbf{<>} <>", {
      d(1, get_visual),
      i(0),
    })
  ),
  s(
    { trig = "emph", snippetType = "autosnippet", priority = 2000 },
    fmta("\\emph{<>} <>", {
      d(1, get_visual),
      i(0),
    })
  ),
  s(
    { trig = "\\emph", snippetType = "autosnippet", priority = 3000 },
    fmta("\\emph{<>}", {
      d(1, get_visual),
    })
  ),
  s(
    { trig = "km", snippetType = "autosnippet", priority = 3000 },
    fmta("$<>$ <>", {
      d(1, get_visual),
      i(0),
    })
  ),
}
