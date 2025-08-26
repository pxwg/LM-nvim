-- Mathematical computation job runner
-- Unified job execution abstraction for external computational tools

local M = {}

-- Run external computation tool with job abstraction
-- @param command string: The command to execute (e.g., "python3", "wolframscript")
-- @param script string: The script content to execute
-- @param timeout number?: Optional timeout in milliseconds
-- @return table: Result from the computation
M.run_computation = function(command, script, timeout)
  local job = require("plenary.job")
  local result = {}
  
  -- Clean up script (remove leading whitespace)
  script = string.gsub(script, "^[\t%s]+", "")
  
  local job_instance = job:new({
    command = command,
    args = {
      "-c",
      script,
    },
    on_exit = function(j)
      result = j:result()
    end,
    timeout = timeout,
  })
  
  job_instance:sync()
  return result
end

-- Run Wolfram/Mathematica computation
-- @param tex_input string: LaTeX input to evaluate
-- @param original_input string?: Original input for display (optional)
-- @return table: Computation result
M.run_mathematica = function(tex_input, original_input)
  original_input = original_input or tex_input
  
  local script = string.format(
    'a = FullSimplify[ToExpression["%s", TeXForm]]; b = TeXForm[a]; Return["%s = " b]',
    tex_input,
    original_input
  )
  
  return M.run_computation("wolframscript", script)
end

-- Run SymPy computation  
-- @param tex_input string: LaTeX input to evaluate
-- @param computation_type string?: Type of computation ("standard", "quantum", etc.)
-- @return table: Computation result
M.run_sympy = function(tex_input, computation_type)
  computation_type = computation_type or "standard"
  
  local script
  
  if computation_type == "quantum" then
    script = string.format([[
from sympy import *
from sympy.physics.quantum import *
def controlled_gate_12(gate):
    return TensorProduct(Matrix([ [1, 0], [0, 0] ]), eye(2))+TensorProduct(Matrix([ [0, 0], [0, 1] ]), gate)
def controlled_gate_21(gate):
    return TensorProduct(eye(2), Matrix([ [1, 0], [0, 0] ]))+TensorProduct(gate, Matrix([ [0, 0], [0, 1] ]))
H = Matrix([ [1, 1], [1, -1] ]) / sqrt(2)
X = Matrix([ [0, 1], [1, 0] ])
Y = Matrix([ [0, -I], [I, 0] ])
Z = Matrix([ [1, 0], [0, -1] ])
e1 = Matrix([ [1], [0], [0], [0] ])
e2 = Matrix([ [0], [1], [0], [0] ])
e3 = Matrix([ [0], [0], [1], [0] ])
e4 = Matrix([ [0], [0], [0], [1] ])
out00 = e1*e1.transpose()
out01 = e2*e2.transpose()
out10 = e3*e3.transpose()
out11 = e4*e4.transpose()
%s
output = latex(res)
print(output)
    ]], tex_input)
  elseif computation_type == "latex2latex" then
    script = string.format(
      "from latex2sympy2 import latex2latex; import re; origin = r'%s'; standard = re.sub(r'\\\\\\\\mathrm{d}', 'd', origin); standard_1 = re.sub(r'\\\\\\\\times', '*', standard); latex = latex2latex(standard_1); output = latex; print(output)",
      tex_input
    )
  else
    -- Standard sympy computation
    script = string.format([[
from sympy import *
origin = r"%s"
parsed = sympify(origin)
output = latex(parsed)
print(output)
    ]], tex_input)
  end
  
  return M.run_computation("python3", script)
end

return M