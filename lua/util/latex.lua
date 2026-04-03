local M = {}

local MATH_NODES = {
  displayed_equation = true,
  inline_formula = true,
  math_environment = true,
}

M.in_env = function(env)
  local node = vim.treesitter.get_node()
  local bufnr = vim.api.nvim_get_current_buf()
  while node do
    if node:type() == "generic_environment" then
      local begin = node:child(0)
      local name = begin and begin:field("name")
      if name and name[1] and vim.treesitter.get_node_text(name[1], bufnr) == "{" .. env .. "}" then
        return true
      end
    end
    node = node:parent()
  end
  return false
end

M.in_text = function()
  local node = vim.treesitter.get_node()
  while node do
    local t = node:type()
    if t == "text_mode" then
      return true
    elseif MATH_NODES[t] then
      return false
    end
    node = node:parent()
  end
  return true
end

M.in_mathzone = function()
  return not M.in_text()
end

M.in_item = function()
  return M.in_env("itemize") or M.in_env("enumerate")
end

M.in_tikz = function()
  return M.in_env("tikzpicture")
end

M.in_center = function()
  return M.in_env("center")
end

M.in_figure = function()
  return M.in_env("figure")
end

M.in_table = function()
  return M.in_env("xltabular")
end

M.in_latex = function()
  return M.in_mathzone()
end

M.clean = function()
  local current_dir = vim.fn.expand("%:p:h")
  local file_types = { "aux", "log", "out", "fls", "fdb_latexmk", "bcf", "run.xml", "toc", "DS_Store", "bak*", "dvi" }
  for _, file_type in ipairs(file_types) do
    local command = "rm " .. current_dir .. "/*." .. file_type
    vim.fn.system(command)
  end
end

M.sympy_calc = function()
  local selected_text = vim.fn.getreg("v")
  print(selected_text)
  vim.api.nvim_out_write(selected_text)
end

return M
