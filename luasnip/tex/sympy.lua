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
    { trig = "pcal", wordTrig = false, snippetType = "autosnippet" },
    fmta("pcal <> pcal", {
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),

  s(
    { trig = "pcal", wordTrig = false, snippetType = "autosnippet", priority = 2000 },
    fmta("pcal <> pcal", {
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),

  -- This one works for now

  s(
    { trig = "ecal", wordTrig = false, snippetType = "autosnippet", priority = 2000 },
    fmta("ecal <> ecal", {
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "pcal", wordTrig = false, snippetType = "autosnippet", priority = 5000 },
    c(1, {
      sn(
        nil,
        fmta("pcal <> pcal", {
          d(1, get_visual),
        })
      ),
      sn(
        nil,
        fmta("mcal <> mcal", {
          d(1, get_visual),
        })
      ),
      sn(
        nil,
        fmta("ncal <> ncal", {
          d(1, get_visual),
        })
      ),
      sn(
        nil,
        fmta("mcalt <> mcalt", {
          d(1, get_visual),
        })
      ),
    }),
    { condition = tex.in_mathzone }
  ),

  s( -- SymPy computation block evaluator using unified engine
    { trig = "pcal.*pcals", regTrig = true, desc = "SymPy block evaluator", snippetType = "autosnippet" },
    d(1, math_engines.presets.sympy_pcal()),
    { condition = tex.in_mathzone }
  ),

  s( -- LaTeX to LaTeX conversion using unified engine
    { trig = "ecal.*ecals", regTrig = true, desc = "LaTeX2LaTeX evaluator", snippetType = "autosnippet" },
    d(1, math_engines.presets.latex2latex_ecal()),
    d(1, function(_, parent)
      -- Gets the part of the block we actually want, and replaces spaces
      -- at the beginning and at the end
      local to_eval = string.gsub(parent.trigger, "^pcal(.*)pcals", "%1")
      to_eval = string.gsub(to_eval, "^%s+(.*)%s+$", "%1")
      to_eval = string.gsub(to_eval, "\\mathrm{i}", "i")
      to_eval = string.gsub(to_eval, "\\left", "")
      to_eval = string.gsub(to_eval, "\\right", "")

      local job = require("plenary.job")

      local sympy_script = string.format(
        "from latex2sympy2 import latex2latex; import re; origin = r'%s'; standard = re.sub(r'\\\\mathrm{d}', 'd', origin); standard_1 = re.sub(r'\\\\times', '*', standard); latex = latex2latex(standard_1); output = latex; print(output)",
        -- origin = re.sub(r'^\s+|\s+$', '', origin)
        -- parsed = parse_expr(origin)
        -- output = origin + parsed
        -- print_latex(parsed)
        to_eval
      )

      sympy_script = string.gsub(sympy_script, "^[\t%s]+", "")
      local result = {}

      job
        :new({
          command = "python3",
          args = {
            "-c",
            sympy_script,
          },
          on_exit = function(j)
            result = j:result()
          end,
        })
        :sync()

      return sn(nil, t(result))
    end)
  ),

  -----------------check code for debugs--------------
  s(
    { trig = "abc.*abc", regTrig = true, desc = "LaTeX2LaTeX debug evaluator", snippetType = "autosnippet" },
    d(1, math_engines.presets.latex2latex_ecal()),
    { condition = tex.in_mathzone }
  ),
  -----------------

  s( -- SymPy LaTeX2LaTeX conversion with custom patterns
    { trig = "sympy.*sympy ", regTrig = true, desc = "SymPy LaTeX2LaTeX evaluator", snippetType = "autosnippet" },
    d(1, math_engines.presets.latex2latex_ecal()),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "qcircuit", wordTrig = false },
    fmta("QCircuit <> QCircuit", {
      i(1),
    }),
    { condition = tex.in_text }
  ),
  s(
    { trig = "qcircuit", wordTrig = false, priority = 2000 },
    fmta("QCircuit <> QCircuit", {
      d(1, get_visual),
    }),
    { condition = tex.in_text }
  ),
  s( -- Quantum circuit computation using unified engine
    { trig = "QCircuit.*QCircuit ", regTrig = true, desc = "QCircuit block evaluator", snippetType = "autosnippet" },
    d(1, math_engines.presets.sympy_quantum_qcircuit()),
  ),
  s(
    { trig = "pex", wordTrig = false, snippetType = "autosnippet" },
    fmta("pexpand <> pexpand", {
      i(1),
    }),
    { condition = tex.in_mathzone }
  ),
  s( -- This one evaluates anything inside the simpy block
    { trig = "pexpand.*pexpands", regTrig = true, desc = "expand block evaluator", snippetType = "autosnippet" },
    d(1, function(_, parent)
      -- Gets the part of the block we actually want, and replaces spaces
      -- at the beginning and at the end
      local to_eval = string.gsub(parent.trigger, "^pexpand(.*)pexpands", "%1")
      to_eval = string.gsub(to_eval, "^%s+(.*)%s+$", "%1")
      to_eval = string.gsub(to_eval, "\\mathrm{i}", "i")
      to_eval = string.gsub(to_eval, "\\left", "")
      to_eval = string.gsub(to_eval, "\\right", "")

      local Job = require("plenary.job")

      local sympy_script = string.format(
        [[
from sympy import symbols, latex
from latex2sympy2 import latex2sympy

origin = r'%s'  
sympy_expr = latex2sympy(origin)
expanded_expr = sympy_expr.expand()
output = origin + ' = ' + latex(expanded_expr)
print(output)
            ]],
        to_eval
      )

      sympy_script = string.gsub(sympy_script, "^[\t%s]+", "")
      local result = ""

      Job:new({
        command = "python3",
        args = {
          "-c",
          sympy_script,
        },
        on_exit = function(j)
          result = j:result()
        end,
      }):sync()

      return sn(nil, t(result))
    end)
  ),
  s( -- This one evaluates anything inside the numpy block
    { trig = "ncal.*ncals", regTrig = true, desc = "numpy block evaluator", snippetType = "autosnippet" },
    d(1, function(_, parent)
      -- Gets the part of the block we actually want, and replaces spaces
      -- at the beginning and at the end
      local to_eval = string.gsub(parent.trigger, "^ncal(.*)ncals", "%1")
      to_eval = string.gsub(to_eval, "^%s+(.*)%s+$", "%1")
      to_eval = string.gsub(to_eval, "\\mathrm{i}", "i")
      to_eval = string.gsub(to_eval, "\\left", "")
      to_eval = string.gsub(to_eval, "\\right", "")

      local Job = require("plenary.job")

      local numpy_script = string.format(
        [[
import numpy as np
from sympy import symbols, simplify
from latex2sympy2 import latex2sympy

origin = r'%s'
sympy_expr = latex2sympy(origin)
numeric_expr = sympy_expr.evalf()
output = origin + ' = ' + str(numeric_expr)
print(output)
      ]],
        to_eval
      )

      numpy_script = string.gsub(numpy_script, "^[\t%s]+", "")
      local result = ""

      Job:new({
        command = "python3",
        args = {
          "-c",
          numpy_script,
        },
        on_exit = function(j)
          result = table.concat(j:result(), "\n")
        end,
      }):sync()

      return sn(nil, t(result))
    end)
  ),
}
