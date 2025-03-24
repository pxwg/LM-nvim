local M = {}

local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
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

-- Function to handle the selection from Telescope and insert formatted string
--- @param file_path string
local function handle_selection(file_path)
  return function(prompt_bufnr)
    actions.close(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    if selection then
      local selected_path = selection.path or selection[1]
      local relative_selected_path = get_relative_note_path(selected_path, file_path)
      local selected_name = get_file_name(selected_path)
      local formatted_string = string.format("[%s](%s)", selected_name, relative_selected_path)
      vim.api.nvim_put({ formatted_string }, "l", true, true)
    else
      vim.notify("No selection made", vim.log.levels.WARN)
    end
  end
end

-- Function to extract the name from a given string (removing unused function warning)
--- @param input_string string
--- @return string
local function extract_name(input_string)
  return input_string:match(".*/(.-)%.%w+:%w+")
end
M.extract_name = extract_name -- Export to avoid unused function warning

-- Function to search for a file name in a directory using Telescope
--- @param file_path string
function M.search_file_name_in_dir(file_path)
  local file_name = get_file_name(file_path)
  if not file_name then
    vim.notify("Invalid file path", vim.log.levels.ERROR)
    return
  end

  require("telescope.builtin").live_grep({
    search_dirs = { vim.fn.expand("~/personal-wiki/") },
    default_text = "(./" .. file_name .. ")",
    type_filter = "markdown",
    initial_mode = "normal", -- Start in normal mode to focus on results
    -- entry_maker = function(entry)
    --   local display = extract_name(entry)
    --   return {
    --     value = entry,
    --     display = display,
    --     ordinal = display,
    --   }
    -- end,
    attach_mappings = function(_, map)
      actions.select_default:replace(handle_selection(file_path))
      return true
    end,
  })
end

return M
