local M = {}

local function is_markdown_image_link(line)
  return line:match("!%[.*%]%((.*)%)")
end

local function get_image_path(line)
  return line:match("!%[.*%]%((.*)%)")
end

local function copy_image_to_destination(src_path, dest_path)
  src_path = src_path:gsub("%%20", " ")
  local command = string.format("cp '%s' '%s'", src_path, dest_path)
  local result = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    vim.notify("Error copying file:" .. result, vim.log.levels.ERROR)
  end
end

copy_image_to_destination(
  "/var/folders/5c/4r2cgs0s3394590rm2t4fh4h0000gn/T/TemporaryItems/NSIRD_screencaptureui_ZDjTpA/截屏2025-03-03%2020.44.38.png",
  "/Users/pxwg-dogggie/Documents/personal-wiki/fig/截屏2025-03-03 20.44.38.png"
)

local function update_image_link(line, new_path)
  return line:gsub("!%[(.*)%]%((.*)%)", string.format("![%s](%s)", "%1", new_path))
end

function M.process_markdown_image_link()
  local line = vim.api.nvim_get_current_line()

  if is_markdown_image_link(line) then
    local image_path = get_image_path(line):gsub("%%20", " ")

    local dest_path = vim.fn.expand("~/Documents/personal-wiki/fig/")
      .. image_path:match("([^/]+)$"):gsub("%%20", "_"):gsub(" ", "")
    local print_path = "./fig/" .. image_path:match("([^/]+)$"):gsub("%%20", "_"):gsub(" ", "")

    copy_image_to_destination(image_path, dest_path)

    local new_line = update_image_link(line, print_path)

    vim.api.nvim_set_current_line(new_line)
  end
end

function M.process_all_markdown_image_links()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    if is_markdown_image_link(line) then
      local image_path = get_image_path(line):gsub("%%20", " ")

      local dest_path = vim.fn.expand("~/Documents/personal-wiki/fig/")
        .. image_path:match("([^/]+)$"):gsub("%%20", "_"):gsub(" ", "")
      local print_path = "./fig/" .. image_path:match("([^/]+)$"):gsub("%%20", "_"):gsub(" ", "")

      copy_image_to_destination(image_path, dest_path)

      local new_line = update_image_link(line, print_path)

      vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new_line })
    end
  end
end

return M
