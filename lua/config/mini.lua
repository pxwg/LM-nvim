local M = {}

local core_setup = false
local files_setup = false

local function md_block_spec(ai_type)
  local parser = vim.treesitter.get_parser(0, "markdown")
  if not parser then
    return
  end
  local root = parser:parse()[1]:root()

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local node = root:named_descendant_for_range(row, col, row, col)
  while node do
    if node:type() == "fenced_code_block" then
      break
    end
    node = node:parent()
  end

  if not node then
    return
  end

  local function ts_to_mini(sr, sc, er, ec)
    if ec == 0 then
      er = er - 1
      local line_text = vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1] or ""
      ec = #line_text
    end

    return {
      from = { line = sr + 1, col = sc + 1 },
      to = { line = er + 1, col = ec },
      vis_mode = "V",
    }
  end

  if ai_type == "a" then
    local sr, sc, er, ec = node:range()
    return ts_to_mini(sr, sc, er, ec)
  end

  for child in node:iter_children() do
    if child:type() == "code_fence_content" then
      local sr, sc, er, ec = child:range()
      return ts_to_mini(sr, sc, er, ec)
    end
  end
end

function M.setup()
  if core_setup then
    return
  end

  require("mini.icons").setup({})
  if files_setup then
    local MiniFiles = require("mini.files")
    MiniFiles.refresh({ content = { prefix = MiniFiles.default_prefix } })
  end

  require("mini.surround").setup({
    custom_surroundings = {
      ["l"] = { output = { left = "[", right = "]()" } },
    },
  })

  local MiniAi = require("mini.ai")
  MiniAi.setup({
    n_lines = 500,
    custom_textobjects = {
      o = MiniAi.gen_spec.treesitter({
        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
      }),
      f = MiniAi.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
      c = MiniAi.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
      t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
      d = { "%f[%d]%d+" },
      w = {
        { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
        "^().*()$",
      },
      u = MiniAi.gen_spec.function_call(),
      U = MiniAi.gen_spec.function_call({ name_pattern = "[%w_]" }),
      e = MiniAi.gen_spec.treesitter({ a = "@math.outer", i = "@math.inner" }),
      r = MiniAi.gen_spec.treesitter({ a = "@reference.outer", i = "@reference.outer" }),
      b = md_block_spec,
    },
  })

  require("mini.pairs").setup({
    modes = { insert = true, command = true, terminal = false },
    mappings = {
      ['"'] = false,
      ["'"] = false,
    },
    skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
    skip_ts = { "string" },
    skip_unbalanced = true,
    markdown = true,
  })

  require("mini.diff").setup({})
  require("mini.git").setup({})
  M.setup_files()

  core_setup = true
end

function M.setup_files()
  if files_setup then
    return
  end

  local MiniFiles = require("mini.files")
  MiniFiles.setup({
    windows = {
      preview = true,
      width_focus = 30,
      width_preview = 30,
    },
    options = {
      use_as_default_explorer = true,
    },
  })

  local show_dotfiles = true
  local function filter_show(_)
    return true
  end
  local function filter_hide(fs_entry)
    return not vim.startswith(fs_entry.name, ".")
  end
  local function toggle_dotfiles()
    show_dotfiles = not show_dotfiles
    local new_filter = show_dotfiles and filter_show or filter_hide
    MiniFiles.refresh({ content = { filter = new_filter } })
  end

  local function map_split(buf_id, lhs, direction, close_on_file)
    local function rhs()
      local new_target_window
      local cur_target_window = MiniFiles.get_explorer_state().target_window
      if cur_target_window == nil then
        return
      end

      vim.api.nvim_win_call(cur_target_window, function()
        vim.cmd("belowright " .. direction .. " split")
        new_target_window = vim.api.nvim_get_current_win()
      end)

      MiniFiles.set_target_window(new_target_window)
      MiniFiles.go_in({ close_on_file = close_on_file })
    end

    local desc = "Open in " .. direction .. " split"
    if close_on_file then
      desc = desc .. " and close"
    end
    vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
  end

  local function files_set_cwd()
    local entry = MiniFiles.get_fs_entry()
    if not entry then
      return
    end
    local directory = vim.fs.dirname(entry.path)
    if directory then
      vim.fn.chdir(directory)
    end
  end

  local group = vim.api.nvim_create_augroup("MiniFilesUserConfig", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "MiniFilesBufferCreate",
    callback = function(args)
      local buf_id = args.data.buf_id
      vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id, desc = "Toggle hidden files" })
      vim.keymap.set("n", "gc", files_set_cwd, { buffer = buf_id, desc = "Set cwd" })
      map_split(buf_id, "<C-w>s", "horizontal", false)
      map_split(buf_id, "<C-w>v", "vertical", false)
      map_split(buf_id, "<C-w>S", "horizontal", true)
      map_split(buf_id, "<C-w>V", "vertical", true)
    end,
  })

  files_setup = true
end

function M.toggle_files(use_cwd)
  M.setup_files()

  local MiniFiles = require("mini.files")
  if vim.g.mini_file_opened then
    MiniFiles.close()
    vim.g.mini_file_opened = false
    return
  end

  local path
  if use_cwd then
    path = vim.uv.cwd()
  elseif vim.bo.filetype == "hello" or vim.bo.filetype == "minifiles" then
    path = vim.fn.getcwd()
  else
    local current_file = vim.api.nvim_buf_get_name(0)
    path = current_file ~= "" and vim.fs.dirname(current_file) or vim.fn.getcwd()
  end

  MiniFiles.open(path, true)
  vim.g.mini_file_opened = true
end

return M
