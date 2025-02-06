local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local previewers = require("telescope.previewers")
local telescope = require("telescope")

-- 自定义预览器函数
local function custom_previewer()
  return previewers.new_buffer_previewer({
    define_preview = function(self, entry, status)
      local preview_file = vim.fn.expand("~/Documents/") -- 确保文件路径正确

      -- print("Preview file: " .. preview_file) -- 添加调试信息

      vim.fn.jobstart({ "cat", preview_file }, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if data then
            -- print("Data received: " .. vim.inspect(data)) -- 添加调试信息
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, data)
          end
        end,
        on_stderr = function(_, data)
          -- print("Error: " .. vim.inspect(data)) -- 添加错误信息
        end,
      })
    end,
  })
end

-- 自定义的 todo-comments 搜索函数
local function custom_todo_comments()
  telescope.extensions["todo-comments"].todo({
    cwd = vim.fn.expand("%:p:h"), -- 设置当前文件的目录
    keywords = "NOTE", -- 只搜索关键词为 NOTE 的内容
    attach_mappings = function(_, _)
      actions.select_default:replace(function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        -- print(vim.inspect(selection))
      end)
      return true
    end,
    previewer = custom_previewer(),
  })
end

-- 绑定快捷键
local map = vim.keymap.set

map("n", "<leader>ft", function()
  custom_todo_comments()
end, { noremap = true, silent = true })
