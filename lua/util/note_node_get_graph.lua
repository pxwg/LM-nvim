local M = {}

local Menu = require("nui.menu")
local length = require("util.note_node_path")

local double_chain = { filepath = "", filename = "" }

--- Function to find files containing the specified text using ripgrep
function double_chain:backward()
  local filepath = self.filepath
  local filename = self.filename .. ".md"
  local directory = filepath:match("(.*/)")
  if not directory then
    vim.notify("Invalid filepath", vim.log.levels.ERROR)
    return {}
  end

  local command = string.format("rg -l '\\(./%s\\)' %s", filename, directory)
  local handle = io.popen(command)
  if handle then
    local result = handle:read("*a")
    handle:close()
    local files_with_text = {}
    for file in result:gmatch("[^\r\n]+") do
      table.insert(files_with_text, file)
    end
    return files_with_text
  else
    vim.notify("No files found", vim.log.levels.WARN)
    return {}
  end
end

--- Function to find markdown links in the current file
--- @return table
function double_chain:forward()
  -- local filename = self.filename
  -- local bufpath = filename .. ".md"
  local filename = vim.fn.expand("%:t:r")
  local bufpath = vim.fn.expand("%:p")
  local command = string.format("rg -o '\\[.*?\\]\\((.*?)\\)' %s", bufpath)
  local handle = io.popen(command)
  if handle then
    local result = handle:read("*a")
    handle:close()
    local links = {}
    for link in result:gmatch("%((.-)%)") do
      table.insert(links, link)
    end
    return links
  else
    vim.notify("No markdown links found", vim.log.levels.WARN)
    return {}
  end
end

local function show_buffer_inlines_menu(buffer_inlines)
  if #buffer_inlines == 0 then
    vim.notify("No References", vim.log.levels.WARN)
    return
  end

  local lines = {}
  for _, name in ipairs(buffer_inlines) do
    name = vim.fn.fnamemodify(name, ":t")
    table.insert(lines, Menu.item(name))
  end

  local menu = Menu({
    position = "50%",
    size = {
      width = 25,
      height = 5,
    },
    border = {
      -- style = { " ", " ", " ", " ", " ", " ", " ", " " },
      style = "rounded",
      text = {
        top = "Select a Reference",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:SelectedItem", -- 设置窗口高亮
    },
  }, {
    lines = lines,
    max_width = 20,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>", "<C-n>" },
      focus_prev = { "k", "<Up>", "<S-Tab>", "<C-p>" },
      close = { "q", "<C-c>", "<ESC>" },
      submit = { "<CR>", "<Space>", "<C-y>" },
    },
    on_submit = function(item)
      local bufpath = vim.api.nvim_buf_get_name(0)
      local dir_path = vim.fn.fnamemodify(bufpath, ":h")
      local file_to_open = dir_path .. "/" .. item.text
      vim.cmd("edit " .. file_to_open)
    end,
  })
  menu:mount()
end

M.show_buffer_inlines_menu = show_buffer_inlines_menu
M.double_chain = double_chain

return M
