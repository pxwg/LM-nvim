-- LaTeX processing utilities
-- Common LaTeX processing functions for mathematical computations

local M = {}

-- Preprocess LaTeX input for computational engines
-- @param input string: Raw LaTeX input
-- @return string: Processed input suitable for computation
M.preprocess_latex = function(input)
  -- Remove leading/trailing whitespace
  input = string.gsub(input, "^%s+(.*)%s+$", "%1")
  
  -- Replace common LaTeX constructs with computation-friendly equivalents
  input = string.gsub(input, "\\mathrm{d}", "d")
  input = string.gsub(input, "\\mathrm{i}", "i")
  
  -- Escape backslashes for external tools
  input = string.gsub(input, "\\", "\\\\")
  
  return input
end

-- Apply pattern replacements for specific computation contexts
-- @param input string: Input to process
-- @param patterns table: Array of {pattern, replacement} pairs
-- @return string: Processed input
M.apply_patterns = function(input, patterns)
  patterns = patterns or {}
  
  for _, pattern_pair in ipairs(patterns) do
    local pattern, replacement = pattern_pair[1], pattern_pair[2]
    input = string.gsub(input, pattern, replacement)
  end
  
  return input
end

-- Quantum computation specific patterns
M.quantum_patterns = {
  { "ts", "TensorProduct" },
  { "I_?(%d)", "eye(%1)" },
  { "C(%w)", "controlled_gate_12(%1)" },
  { "dagger", ".conjugate().transpose()" }
}

-- Extract content from delimited blocks (e.g., "mcal...mcals")
-- @param trigger string: Full trigger text containing delimited content
-- @param start_delimiter string: Starting delimiter
-- @param end_delimiter string: Ending delimiter  
-- @return string: Extracted content
M.extract_delimited_content = function(trigger, start_delimiter, end_delimiter)
  local pattern = "^" .. start_delimiter .. "(.*)" .. end_delimiter
  local content = string.gsub(trigger, pattern, "%1")
  return string.gsub(content, "^%s+(.*)%s+$", "%1")
end

return M