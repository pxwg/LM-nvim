local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local f = ls.function_node
local d = ls.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local line_begin = require("luasnip.extras.expand_conditions").line_begin
local tex = require("util.latex")

-- Import the unified math computation engine
local math_engines = require("core.math.engines")

local get_visual = function(args, parent)
  if #parent.snippet.env.SELECT_RAW > 0 then
    return sn(nil, t(parent.snippet.env.SELECT_RAW))
  else -- If SELECT_RAW is empty, return a blank insert node
    return sn(nil, i(1))
  end
end

return {
  s(
    { trig = "mcal", wordTrig = false, snippetType = "autosnippet", priority = 2000 },
    fmta("mcal <> mcal", {
      i(0),
    }),
    { condition = tex.in_latex }
  ),

  s(
    { trig = "mcal", wordTrig = false, snippetType = "autosnippet", priority = 3000 },
    fmta("mcal <> mcal", {
      d(1, get_visual),
    }),
    { condition = tex.in_latex }
  ),

  s(
    { trig = "mcal", wordTrig = false, snippetType = "autosnippet", priority = 4000 },
    c(1, {
      sn(
        nil,
        fmta("mcal <> mcal", {
          d(1, get_visual),
        })
      ),
      sn(
        nil,
        fmta("pcal <> pcal", {
          d(1, get_visual),
        })
      ),
    }),
    { condition = tex.in_latex }
  ),
  s( -- Mathematica computation block evaluator using unified engine
    { trig = "mcal.*mcals", regTrig = true, desc = "Mathematica block evaluator", snippetType = "autosnippet" },
    d(1, math_engines.presets.mathematica_mcal()),
    { condition = tex.in_latex }
  ),
}
