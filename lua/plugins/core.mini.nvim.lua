-- local zk = require("zk")
local function md_block_spec(ai_type, id, opts)
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
  else
    for child in node:iter_children() do
      if child:type() == "code_fence_content" then
        local sr, sc, er, ec = child:range()
        return ts_to_mini(sr, sc, er, ec)
      end
    end
    return nil
  end
end

return {
  "echasnovski/mini.nvim",
  version = false,
  event = "VeryLazy",
  keys = {
    {
      "<leader>e",
      function()
        if vim.g.mini_file_opened then
          require("mini.files").close()
          vim.g.mini_file_opened = false
        else
          local current_file = vim.api.nvim_buf_get_name(0)
          local cwd = vim.fn.getcwd()
          if vim.bo.filetype == "hello" or vim.bo.filetype == "minifiles" then
            require("mini.files").open(cwd, true)
          else
            require("mini.files").open(vim.fs.dirname(current_file), true)
          end
          vim.g.mini_file_opened = true
        end
      end,
      desc = "Open mini.files (Directory of Current File)",
    },
    {
      "<leader>E",
      function()
        if vim.g.mini_file_opened then
          require("mini.files").close()
          vim.g.mini_file_opened = false
        else
          require("mini.files").open(vim.uv.cwd(), true)
          vim.g.mini_file_opened = true
        end
      end,
      desc = "Open mini.files (cwd)",
    },
  },
  config = function()
    require("mini.icons").setup({})

    require("mini.surround").setup({
      custom_surroundings = {
        ["l"] = { output = { left = "[", right = "]()" } },
      },
    })

    local MiniAi = require("mini.ai")
    MiniAi.setup({
      n_lines = 500,
      custom_textobjects = {
        o = MiniAi.gen_spec.treesitter({ -- code block
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }),
        f = MiniAi.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
        c = MiniAi.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
        t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
        d = { "%f[%d]%d+" }, -- digits
        w = { -- Word with case
          { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
          "^().*()$",
        },
        u = MiniAi.gen_spec.function_call(), -- u for "Usage"
        U = MiniAi.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
        e = MiniAi.gen_spec.treesitter({ a = "@math.outer", i = "@math.inner" }),
        b = md_block_spec,
      },
    })

    require("mini.pairs").setup({
      modes = { insert = true, command = true, terminal = false },
      mappings = {
        ['"'] = false,
        ["'"] = false,
      },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { "string" },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
    })

    require("mini.files").setup({
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
    local filter_show = function(fs_entry)
      return true
    end
    local filter_hide = function(fs_entry)
      return not vim.startswith(fs_entry.name, ".")
    end

    local toggle_dotfiles = function()
      show_dotfiles = not show_dotfiles
      local new_filter = show_dotfiles and filter_show or filter_hide
      require("mini.files").refresh({ content = { filter = new_filter } })
    end

    local map_split = function(buf_id, lhs, direction, close_on_file)
      local rhs = function()
        local new_target_window
        local cur_target_window = require("mini.files").get_explorer_state().target_window
        if cur_target_window ~= nil then
          vim.api.nvim_win_call(cur_target_window, function()
            vim.cmd("belowright " .. direction .. " split")
            new_target_window = vim.api.nvim_get_current_win()
          end)

          require("mini.files").set_target_window(new_target_window)
          require("mini.files").go_in({ close_on_file = close_on_file })
        end
      end

      local desc = "Open in " .. direction .. " split"
      if close_on_file then
        desc = desc .. " and close"
      end
      vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
    end

    local MiniFiles = require("mini.files")
    local files_set_cwd = function()
      local cur_entry_path = MiniFiles.get_fs_entry().path
      local cur_directory = vim.fs.dirname(cur_entry_path)
      if cur_directory ~= nil then
        vim.fn.chdir(cur_directory)
      end
    end

    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesBufferCreate",
      callback = function(args)
        local buf_id = args.data.buf_id

        vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id, desc = "Toggle hidden files" })

        vim.keymap.set("n", "gc", files_set_cwd, { buffer = args.data.buf_id, desc = "Set cwd" })

        map_split(buf_id, "<C-w>s", "horizontal", false)
        map_split(buf_id, "<C-w>v", "vertical", false)
        map_split(buf_id, "<C-w>S", "horizontal", true)
        map_split(buf_id, "<C-w>V", "vertical", true)
      end,
    })

    local MiniDiffs = require("mini.diff")
    MiniDiffs.setup({})

    local MiniGit = require("mini.git")
    MiniGit.setup({})

    -- delete index while delete note file
    -- vim.api.nvim_create_autocmd("User", {
    --   pattern = "MiniFilesActionDelete",
    --   callback = function(args)
    --     local deleted_path = args.data.from
    --     if not deleted_path:match("/wiki/note/.*%.typ$") then
    --       return
    --     end
    --
    --     local note_filename = vim.fn.fnamemodify(deleted_path, ":t")
    --     local note_id = note_filename:match("^(%d+)")
    --     if note_id then
    --       zk.remove_note(note_id)
    --       vim.notify("ZK: Removed " .. note_filename .. " from link.typ", vim.log.levels.INFO)
    --     end
    --   end,
    -- })
  end,
}
