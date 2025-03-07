local autocmd = vim.api.nvim_create_autocmd

-- set up rime_ls lsp when enter tex
autocmd("FileType", {
  pattern = "plaintex",
  callback = function()
    vim.cmd("LspStart rime_ls")
  end,
})

-- color preview
autocmd("BufRead", {
  callback = function()
    vim.cmd("ColorizerAttachToBuffer")
  end,
})

-- -- fzf with frequency
-- local function log_file_access()
--   local file_path = vim.fn.expand("%:p")
--   if file_path ~= "" then
--     os.execute("fre --add " .. file_path)
--   end
-- end

-- -- Register the function to log file access on BufEnter event
-- autocmd("BufEnter", {
--   pattern = "*",
--   callback = log_file_access,
-- })

-- auto save cursor position
autocmd("BufWinLeave", {
  pattern = "*",
  callback = function()
    vim.cmd("silent! mkview")
  end,
})

autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    vim.cmd("silent! loadview")
  end,
})

autocmd("BufEnter", {
  pattern = "*.md",
  callback = function()
    require("otter").activate()
  end,
})

autocmd("VimLeavePre", {
  callback = function()
    local bufs = vim.api.nvim_list_bufs()
    for _, buf in ipairs(bufs) do
      if vim.bo[buf].filetype == "neo-tree" or vim.bo[buf].filetype == "copilot-chat" then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end,
})

autocmd("CursorMovedI", {
  callback = function()
    local statusline_parts = {
      "%f", -- 文件名
      "%m", -- 修改标志
      "%=",
      "", -- 占位符
      require("util.battery").get_battery_icon() .. " ",
    }
    statusline_parts[4] = "[" .. require("util.rime_ls").rime_toggle_word() .. "] "
    require("util.rime_ls").change_cursor_color()
    vim.o.statusline = table.concat(statusline_parts)
  end,
})

-- auto change insert mode
require("util.math_autochange")

-- open rime_ls
local job_id = vim.fn.jobstart("rime_ls --listen", {
  on_stdout = function() end,
  on_stderr = function() end,
  on_exit = function(_, code)
    if code ~= 0 then
      vim.api.nvim_err_writeln("rime_ls exited with code " .. code)
    end
  end,
})

-- Create an autocommand to stop the job when Neovim exits
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    vim.fn.jobstop(job_id)
  end,
})

-- Enable Treesitter highlighting for Markdown files
-- autocmd("FileType", {
--   pattern = "markdown",
--   callback = function()
--     vim.cmd("TSBufEnable highlight")
--   end,
-- })

-- Firenvim settings

if vim.g.started_by_firenvim then
  vim.api.nvim_create_autocmd("BufWritePost", {
    callback = require("util.firenvim").adjust_minimum_lines,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    callback = require("util.firenvim").adjust_minimum_lines,
  })

  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "*.txt",
    command = "set filetype=markdown",
  })
end

-- avate.nvim
autocmd("FileType", {
  pattern = "AvanteInput",
  callback = function()
    vim.cmd("LspStart rime_ls")
    vim.cmd("RenderMarkdown")
    vim.api.nvim_buf_set_keymap(0, "n", "q", ":q<CR>", { noremap = true, silent = true })
  end,
})

autocmd("FileType", {
  pattern = { "Avante", "copilot-chat" },
  callback = function()
    vim.cmd("RenderMarkdown")
    vim.cmd("TSBufEnable highlight")
  end,
})

-- auto close avante buffer
autocmd("VimLeavePre", {
  callback = function()
    local bufs = vim.api.nvim_list_bufs()
    for _, buf in ipairs(bufs) do
      if string.match(vim.bo[buf].filetype, "Avante") then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end,
})

-- Generate a unique log file name for each Neovim instance
local function get_front_window_id()
  local result = vim.fn.system("hs -c 'GetWinID()'")
  return result:match("%d+")
end

local log_file = vim.fn.expand("~/.local/state/nvim/windows/") .. get_front_window_id() .. "_nvim_startup.log"

-- Delete the unique log file on Neovim exit
autocmd("VimLeavePre", {
  callback = function()
    os.remove(log_file)
  end,
})

-- Function to trim trailing blank lines from the current buffer
local function trim_trailing_blank_lines()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local last_non_blank = #lines

  -- Find the last non-blank line
  for i = #lines, 1, -1 do
    if lines[i]:match("^%s*$") then
      last_non_blank = i - 1
    else
      break
    end
  end

  -- Set the buffer lines, removing trailing blank lines
  vim.api.nvim_buf_set_lines(0, last_non_blank, -1, false, {})
  vim.cmd("silent! undojoin")
end

-- Create a command to run the function
vim.api.nvim_create_user_command("TrimTrailingBlankLines", trim_trailing_blank_lines, {})

-- Optionally, you can run the function automatically on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = trim_trailing_blank_lines,
})

autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    --     vim.cmd("TSBufEnable highlight")
    vim.opt_local.spell = true
    vim.cmd("normal! zM")
  end,
})

autocmd("BufEnter", {
  pattern = "*.md",
  callback = function()
    vim.cmd([[
      syn include @tex syntax/tex.vim
      syn region mkdMath start="\\\@<!\$" end="\$" skip="\\\$" contains=@tex keepend
      syn region mkdMath start="\\\@<!\$\$" end="\$\$" skip="\\\$" contains=@tex keepend
      syn match markdownH1 "^# .*$"
      syn match markdownH2 "^## .*$"
      syn match markdownH3 "^### .*$"
      syn match markdownH4 "^#### .*$"
      syn match markdownH5 "^##### .*$"
      syn match markdownH6 "^###### .*$"

      " Link syntax to highlight groups
      highlight link markdownH1 rainbow1
      highlight link markdownH2 rainbow2
      highlight link markdownH3 rainbow3
      highlight link markdownH4 rainbow4
      highlight link markdownH5 rainbow5
      highlight link markdownH6 rainbow6

    ]])
  end,
})

autocmd("VimResized", {
  callback = function()
    vim.cmd("wincmd =")
  end,
})

require("util.note_md")
