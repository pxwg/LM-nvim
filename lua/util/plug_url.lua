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
        local plugin_name = get_first_string(item)
        if plugin_name then
          table.insert(plugin_names, plugin_name)
        end
        if item.dependencies then
          for _, dep in ipairs(item.dependencies) do
            if type(dep) == "string" then
              table.insert(plugin_names, dep)
            elseif type(dep) == "table" then
              local dep_name = get_first_string(dep)
              if dep_name then
                table.insert(plugin_names, dep_name)
              end
            end
          end
        end
      else
        local plugin_name = get_first_string(tbl)
        if plugin_name then
          table.insert(plugin_names, plugin_name)
        end
        if tbl.dependencies then
          for _, dep in ipairs(tbl.dependencies) do
            if type(dep) == "string" then
              table.insert(plugin_names, dep)
            elseif type(dep) == "table" then
              local dep_name = get_first_string(dep)
              if dep_name then
                table.insert(plugin_names, dep_name)
              end
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
      -- style = { " ", " ", " ", " ", " ", " ", " ", " " },
      style = "rounded",
      text = {
        top = "Choose a Plugin",
        top_align = "center",
      },
    },
    win_options = {
      -- winblend = 10,
      winhighlight = "Normal:Normal",
    },
  }, {
    lines = lines,
    max_width = 20,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>", "<C-n>" },
      focus_prev = { "k", "<Up>", "<S-Tab>", "<C-p>" },
      close = { "q", "<C-c>" },
      submit = { "<CR>", "<Space>", "<C-y>" },
    },
    on_submit = function(item)
      local open = item.text:gsub(" :", "")
      open_github_url(open)
    end,
  })

  -- mount the component
  menu:mount()
end

-- Define a highlight group for the symbol
local ns_id = vim.api.nvim_create_namespace("PluginSymbol")
vim.api.nvim_set_hl(0, "PluginSymbol", { fg = "#74c7ec" })
vim.api.nvim_set_hl(0, "AuthSymbol", { fg = "#b4befe" })
vim.api.nvim_set_hl(0, "NameSymbol", { fg = "#f38ba8" })

local function get_plugin_name()
  local plugin_names = get_plugin_names()

  if #plugin_names > 1 then
    for i, name in ipairs(plugin_names) do
      plugin_names[i] = " :" .. name
    end
    show_plugin_menu(plugin_names)

    -- Apply the highlight to the symbol
    for i, name in ipairs(plugin_names) do
      local line = i - 1 -- Adjust for 0-based indexing
      local symbol, rest = string.match(name, "( :)(.+)$")
      if symbol and rest then
        local before_slash, after_slash = string.match(rest, "([^/]+)/(.+)")
        if before_slash and after_slash then
          vim.highlight.range(0, ns_id, "PluginSymbol", { line, 0 }, { line, #symbol })
          vim.highlight.range(0, ns_id, "AuthSymbol", { line, #symbol }, { line, #symbol + #before_slash })
          vim.highlight.range(
            0,
            ns_id,
            "NameSymbol",
            { line, #symbol + #before_slash + 1 },
            { line, #symbol + #before_slash + 1 + #after_slash }
          )
        end
      end
    end
  elseif #plugin_names == 1 then
    open_github_url(plugin_names[1])
  end
end

_G.get_plugin_name = get_plugin_name
