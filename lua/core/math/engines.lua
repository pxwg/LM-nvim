-- Mathematical computation engines
-- Unified interface for different mathematical computation tools

local job_runner = require("core.math.job_runner")
local latex_processor = require("core.math.latex_processor")

local M = {}

-- Computation engine types
M.ENGINES = {
  MATHEMATICA = "mathematica",
  SYMPY = "sympy",
  SYMPY_QUANTUM = "sympy_quantum",
  LATEX2LATEX = "latex2latex"
}

-- Execute mathematical computation using specified engine
-- @param engine string: Engine type (use M.ENGINES constants)
-- @param input string: LaTeX input to compute
-- @param options table?: Optional configuration
-- @return table: Computation result
M.compute = function(engine, input, options)
  options = options or {}
  
  -- Preprocess the input
  local processed_input = latex_processor.preprocess_latex(input)
  
  if engine == M.ENGINES.MATHEMATICA then
    return job_runner.run_mathematica(processed_input, options.original_input)
    
  elseif engine == M.ENGINES.SYMPY then
    return job_runner.run_sympy(processed_input, "standard")
    
  elseif engine == M.ENGINES.SYMPY_QUANTUM then
    -- Apply quantum-specific patterns
    local quantum_input = latex_processor.apply_patterns(processed_input, latex_processor.quantum_patterns)
    return job_runner.run_sympy(quantum_input, "quantum")
    
  elseif engine == M.ENGINES.LATEX2LATEX then
    return job_runner.run_sympy(processed_input, "latex2latex")
    
  else
    error("Unknown computation engine: " .. tostring(engine))
  end
end

-- Helper function to create computation snippet
-- @param engine string: Computation engine to use
-- @param delimiters table: {start, end} delimiters for extraction
-- @return function: Snippet function for luasnip
M.create_computation_snippet = function(engine, delimiters)
  return function(_, parent)
    local trigger = parent.trigger
    local start_delim, end_delim = delimiters[1], delimiters[2]
    
    -- Extract content from delimited trigger
    local to_eval = latex_processor.extract_delimited_content(trigger, start_delim, end_delim)
    
    -- Compute result
    local result = M.compute(engine, to_eval, { original_input = to_eval })
    
    -- Return snippet node
    local ls = require("luasnip")
    return ls.snippet_node(nil, ls.text_node(result))
  end
end

-- Preset computation snippets for common use cases
M.presets = {
  -- Mathematica computation with mcal delimiters
  mathematica_mcal = function()
    return M.create_computation_snippet(M.ENGINES.MATHEMATICA, {"mcal", "mcals"})
  end,
  
  -- SymPy computation with pcal delimiters  
  sympy_pcal = function()
    return M.create_computation_snippet(M.ENGINES.SYMPY, {"pcal", "pcals"})
  end,
  
  -- Quantum SymPy computation with QCircuit delimiters
  sympy_quantum_qcircuit = function()
    return M.create_computation_snippet(M.ENGINES.SYMPY_QUANTUM, {"QCircuit", "QCircuit "})
  end,
  
  -- LaTeX to LaTeX conversion with ecal delimiters
  latex2latex_ecal = function()
    return M.create_computation_snippet(M.ENGINES.LATEX2LATEX, {"ecal", "ecals"})
  end
}

return M