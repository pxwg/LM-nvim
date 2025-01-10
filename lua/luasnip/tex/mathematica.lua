local ls = require("luasnip")
local sa = require("sniprun.api")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local d = ls.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta
local tex = require("util.latex")

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
  s( -- this one evaluates anything inside the simpy block
    {
      trig = "mcal.*mcals",
      regTrig = true,
      desc = "sympy block evaluator",
      snippetType = "autosnippet",
      priority = 10000,
    },
    d(1, function(_, parent)
      -- gets the part of the block we actually want, and replaces spaces
      -- at the beginning and at the end
      local to_eval = string.gsub(parent.trigger, "^mcal(.*)mcals", "%1")
      to_eval = string.gsub(to_eval, "^%s+(.*)%s+$", "%1")
      local scan_input = to_eval

      -- replace single backslashes with double backslashes
      to_eval = string.gsub(to_eval, "\\mathrm{d}", "d")
      to_eval = string.gsub(to_eval, "\\mathrm{i}", "i")
      to_eval = string.gsub(to_eval, "\\", "\\\\")

      local job = require("plenary.job")

      local sympy_script =
        string.format('a = FullSimplify[ToExpression["%s", TeXForm]]; b = TeXForm[a]; Return["%s = " b]', to_eval, to_eval, scan_input)

      sympy_script = string.gsub(sympy_script, "^[\t%s]+", "")
      local result = {}

      job
        :new({
          command = "wolframscript",
          args = {
            "-c",
            sympy_script,
          },
          on_exit = function(j)
            result = j:result()
          end,
          -- timeout = 210000000,
        })
        :sync()

      return sn(nil, t(  result))
    end)
  ),
  s(
    {
      trig = "mcalt.*mcalts",
      regTrig = true,
      desc = "sympy block evaluator",
      snippetType = "autosnippet",
      priority = 2000,
    },
    d(1, function(_, parent)
      -- gets the part of the block we actually want, and replaces spaces
      -- at the beginning and at the end
      _G.result = ""
      local to_eval = string.gsub(parent.trigger, "^mcalt(.*)mcalts", "%1")
      to_eval = string.gsub(to_eval, "^%s+(.*)%s+$", "%1")
      local input = to_eval

      -- replace single backslashes with double backslashes
      to_eval = string.gsub(to_eval, "\\mathrm{d}", "d")
      to_eval = string.gsub(to_eval, "\\mathrm{i}", "i")
      to_eval = string.gsub(to_eval, "\\", "\\\\")

      -- local job = require("plenary.job")

      local sympy_script =
        string.format('a = FullSimplify[ToExpression["%s", TeXForm]]; b = TeXForm[a]; Print[b]', to_eval)

      local init = _G.result
      local result = init

      sa.run_string(
        sympy_script,
        "mathematica",
        require("sniprun").setup({
          display = { "Api" },
        })
      )
      return sn(nil, t(input .. " = "))
    end)
  ),
}
