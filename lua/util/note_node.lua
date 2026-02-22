local M = {}

-- Function to extract the file name from a file path
--- @param file_path string
--- @return string
local function get_file_name(file_path)
  return file_path:match("^.+/(.+)$")
end

M.get_file_name = get_file_name

local function get_relative_note_path(file_path, current_buffer_path)
  local clean_file_path = file_path:gsub("/Documents", "")
  local clean_buffer_path = current_buffer_path:gsub("/Documents", "")

  local file_parts = vim.split(clean_file_path, "/")
  local buffer_parts = vim.split(clean_buffer_path, "/")

  local i = 1
  while i <= #file_parts and i <= #buffer_parts and file_parts[i] == buffer_parts[i] do
    i = i + 1
  end

  local relative_parts = {}
  for j = i, #file_parts do
    table.insert(relative_parts, file_parts[j])
  end

  local relative_path = table.concat(relative_parts, "/")

  return "./" .. relative_path
end

M.get_relative_note_path = get_relative_note_path

-- Function to extract the name from a given string (removing unused function warning)
--- @param input_string string
--- @return string
local function extract_name(input_string)
  return input_string:match(".*/(.-)%.%w+:%w+")
end
M.extract_name = extract_name -- Export to avoid unused function warning

-- Function to search for a file name in a directory using Snacks.picker
--- @param file_path string
function M.search_file_name_in_dir(file_path)
  local file_name = get_file_name(file_path)
  if not file_name then
    vim.notify("Invalid file path", vim.log.levels.ERROR)
    return
  end

  Snacks.picker.grep({
    cwd = vim.fn.expand("~/personal-wiki/"),
    search = "(./" .. file_name .. ")",
    ft = "markdown",
  })
end

return M
