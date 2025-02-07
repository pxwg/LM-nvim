local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event

local function get_first_string(tbl)
  for _, v in ipairs(tbl) do
    if type(v) == "string" then
      return v
    elseif type(v) == "table" then
      local result = get_first_string(v)
      if result then
        return result
      end
    end
  end
end

local function get_plugin_names()
  local bufnr = vim.api.nvim_get_current_buf()
  local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local code = table.concat(content, "\n")

  local code_tab = load(code)()

  local plugin_names = {}

  local function process_table(tbl)
    for _, item in ipairs(tbl) do
      if type(item) == "table" then
        table.insert(plugin_names, get_first_string(item))
        if item.dependencies then
          for _, dep in ipairs(item.dependencies) do
            if type(dep) == "string" then
              table.insert(plugin_names, dep)
            elseif type(dep) == "table" then
              table.insert(plugin_names, get_first_string(dep))
            end
          end
        end
      else
        table.insert(plugin_names, get_first_string(tbl))
        if tbl.dependencies then
          for _, dep in ipairs(tbl.dependencies) do
            if type(dep) == "string" then
              table.insert(plugin_names, dep)
            elseif type(dep) == "table" then
              table.insert(plugin_names, get_first_string(dep))
            end
          end
        end
        break
      end
    end
  end

  process_table(code_tab)

  return plugin_names
end

local function open_github_url(plugin_name)
  if plugin_name then
    local url = "https://www.github.com/" .. plugin_name
    vim.loop.spawn("open", { args = { url } })
  else
    print("No valid plugin name found")
  end
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
        top = "Choose a Plugin",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:TelescopeNormal,FloatBorder:TelescopeBorder,FloatTitle:TelescopePromptTitle",
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
    on_submit = function(item)
      open_github_url(item.text)
    end,
  })

  -- mount the component
  menu:mount()
end

local function get_plugin_name()
  local plugin_names = get_plugin_names()

  if #plugin_names > 1 then
    show_plugin_menu(plugin_names)
  elseif #plugin_names == 1 then
    open_github_url(plugin_names[1])
  end
end

_G.get_plugin_name = get_plugin_name
