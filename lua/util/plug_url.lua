local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event

local function get_plugin_names()
  local bufnr = vim.api.nvim_get_current_buf()
  local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local code = table.concat(content, "\n")

  local plugin_names = {}
  local seen = {}
  for name in code:gmatch('{%s*"([^"]+/[^"]+)",') do
    if not seen[name] then
      table.insert(plugin_names, name)
      seen[name] = true
    end
  end

  return plugin_names
end

local function show_plugin_menu(plugin_names)
  local lines = {}
  for _, name in ipairs(plugin_names) do
    table.insert(lines, Menu.item(name))
  end

  local menu = Menu({
    position = "50%",
    size = {
      width = 25,
      height = 5,
    },
    border = {
      style = { " ", " ", " ", " ", " ", " ", " ", " " },
      text = {
        top = "[Choose a Plugin]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:TelescopeNormal,FloatBorder:TelescopeNormal",
    },
  }, {
    lines = lines,
    max_width = 20,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "q", "<C-c>" },
      submit = { "<CR>", "<Space>" },
    },
  })

  -- mount the component
  menu:mount()
end

local function get_plugin_name()
  local plugin_names = get_plugin_names()

  if #plugin_names > 1 then
    return show_plugin_menu(plugin_names)
  elseif #plugin_names == 1 then
    return plugin_names[1]
  end
end

local function open_github_url()
  local plugin_name = get_plugin_name()
  if plugin_name then
    local url = "https://www.github.com/" .. plugin_name
    vim.loop.spawn("open", { args = { url } })
  else
    print("No valid plugin name found")
  end
end

_G.open_github_url = open_github_url
