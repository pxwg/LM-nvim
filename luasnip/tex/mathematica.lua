local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local d = ls.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta
local tex = require("util.latex")

-- Import the unified math computation engine
local math_engines = require("core.math.engines")

local get_visual = function(args, parent)
  if #parent.snippet.env.select_raw > 0 then
    return sn(nil, t(parent.snippet.env.select_raw))
  else -- if select_raw is empty, return a blank insert node
    return sn(nil, i(1))
  end
end

return {
  s(
    { trig = "mcal", wordtrig = false, snippettype = "autosnippet", priority = 2000 },
    fmta("mcal <> mcal", {
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),

  s(
    { trig = "mcal", wordtrig = false, snippettype = "autosnippet", priority = 3000 },
    fmta("mcal <> mcal", {
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),

  s(
    { trig = "mcal", wordtrig = false, snippettype = "autosnippet", priority = 3000 },
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
    { condition = tex.in_mathzone }
  ),
  s( -- Mathematica computation block evaluator using unified engine
    {
      trig = "mcal.*mcals",
      regTrig = true,
      desc = "Mathematica block evaluator",
      snippetType = "autosnippet",
      priority = 10000,
    },
    d(1, math_engines.presets.mathematica_mcal()),
    { condition = tex.in_mathzone }
  ),
}
