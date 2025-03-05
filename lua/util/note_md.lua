local config = require("img-clip.config")
local paste = require("img-clip.paste")

local M = {}

---@param config_opts? table
M.setup = function(config_opts)
  config.setup(config_opts)
end

---@param api_opts? table
---@param input? string
M.paste_image = function(api_opts, input)
  config.api_opts = api_opts or {}
  return paste.paste_image(input)
end

---@param api_opts? table
---@param input? string
M.pasteImage = function(api_opts, input)
  config.api_opts = api_opts or {}
  return paste.paste_image(input)
end

local function get_relative_path(file_path, current_buffer_path, arg)
  arg = arg or {}

  local home_path = vim.fn.expand("~")
  local relative_path = vim.fn.fnamemodify(file_path, ":~:.")
  local common_prefix = vim.fn.fnamemodify(current_buffer_path, ":~:.")

  if common_prefix == home_path then
    return file_path
  end

  if relative_path:sub(1, #common_prefix) == common_prefix then
    relative_path = relative_path:sub(#common_prefix + 2)
  end

  return "./" .. relative_path
end

M.get_relative_path = get_relative_path

local function generate_link(relative_path)
  local file_name = vim.fn.fnamemodify(relative_path, ":t:r")
  return string.format("[%s](%s)", file_name, relative_path)
end

local original_paste = vim.paste

vim.paste = function(lines, phase)
  if phase == -1 and vim.bo.filetype == "markdown" then
    local file_path = lines[1]
    if file_path:match("%.md$") then
      local path = vim.api.nvim_buf_get_name(0)
      local relative_path = get_relative_path(file_path, path)
      local markdown_link = generate_link(relative_path)

      vim.api.nvim_put({ markdown_link }, "l", true, true)
      return true
    end
  end
  return original_paste(lines, phase)
end

return M
