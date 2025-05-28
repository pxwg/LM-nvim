local md_hl = require("util.latex_highlight")
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

-- Use a more efficient event pattern
local statusline_update_timer = vim.loop.new_timer()
autocmd({ "InsertEnter", "InsertLeave", "BufEnter", "FocusGained" }, {
  callback = function()
    if vim.bo.buftype ~= "terminal" or vim.bo.filetype ~= "checkhealth" then
      require("util.statusline").update_hl()
      -- Debounce cursor movement events
      if statusline_update_timer then
        statusline_update_timer:stop()
      end
    end
  end,
})

-- Debounced updates for cursor movements
autocmd({ "CursorMovedI", "CursorMoved" }, {
  callback = function()
    if vim.bo.buftype ~= "terminal" or vim.bo.buftype ~= "nofile" then
      if statusline_update_timer then
        statusline_update_timer:stop()
        statusline_update_timer:start(
          300,
          0,
          vim.schedule_wrap(function()
            require("util.statusline").update_hl()
          end)
        )
      end
    end
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
    vim.cmd("set filetype=markdown")
    -- vim.cmd("RenderMarkdown")
    -- vim.cmd("TSBufEnable highlight")
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

-- -- Function to trim trailing blank lines from the current buffer
-- local function trim_trailing_blank_lines()
--   local bufnr = vim.api.nvim_get_current_buf()
--   local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--
--   local last_non_blank = #lines
--   while last_non_blank > 0 and lines[last_non_blank]:match("^%s*$") do
--     last_non_blank = last_non_blank - 1
--   end
--
--   if last_non_blank < #lines then
--     vim.cmd([[
--       let save_view = winsaveview()
--       let save_ul = &undolevels
--       set undolevels=-1
--       silent! execute "keepjumps lockmarks " . (]] .. last_non_blank .. [[+1) . ",$delete _"
--       let &undolevels = save_ul
--       call winrestview(save_view)
--     ]])
--   end
-- end
--
-- -- Create a command to run the function
-- vim.api.nvim_create_user_command("TrimTrailingBlankLines", trim_trailing_blank_lines, {})
--
-- -- Optionally, you can run the function automatically on save
-- vim.api.nvim_create_autocmd("BufWritePre", {
--   pattern = "*",
--   callback = function()
--     trim_trailing_blank_lines()
--   end,
-- })

autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.md", "*.copilot-chat" },
  callback = function()
    -- mkdMath()
  end,
})

autocmd("VimResized", {
  callback = function()
    vim.cmd("wincmd =")
  end,
})

require("util.note_md")

vim.api.nvim_create_autocmd("User", {
  pattern = "TelescopePreviewerLoaded",
  callback = function(args)
    if args.data.filetype == "markdown" then
      -- mkdMath()
      -- mkdMath()
      vim.cmd("redraw")
    end
  end,
})

--- firenvim
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

--- diagnostic
local og_virt_text
local og_virt_line
vim.api.nvim_create_autocmd({ "CursorMoved", "DiagnosticChanged" }, {
  group = vim.api.nvim_create_augroup("diagnostic_only_virtlines", {}),
  callback = function()
    if og_virt_line == nil then
      og_virt_line = vim.diagnostic.config().virtual_lines
    end

    -- ignore if virtual_lines.current_line is disabled
    if not (og_virt_line and og_virt_line.current_line) then
      if og_virt_text then
        vim.diagnostic.config({ virtual_text = og_virt_text })
        og_virt_text = nil
      end
      return
    end

    if og_virt_text == nil then
      og_virt_text = vim.diagnostic.config().virtual_text
    end

    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

    if vim.tbl_isempty(vim.diagnostic.get(0, { lnum = lnum })) then
      vim.diagnostic.config({ virtual_text = og_virt_text })
    else
      vim.diagnostic.config({ virtual_text = false })
    end
  end,
})

-- Create a namespace for the math delimiter concealer
local ns_id = vim.api.nvim_create_namespace("math_delimiter_concealer")

-- Function to conceal standalone math delimiter lines
local function conceal_math_delimiters(bufnr)
  bufnr = bufnr or 0

  -- Get buffer lines
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Track which lines to conceal (only those with just $$ and nothing else)
  for i, line in ipairs(lines) do
    -- Check if the line contains only $$ and optional whitespace
    if line:match("^%s*%$%$%s*$") then
      print("Concealing line " .. i .. ": " .. line)
      -- Found a line with only $$, conceal it entirely
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, 0, {
        end_row = i - 1,
        end_col = 0, -- To the end of line
        conceal = "", -- Empty string means completely hidden
      })
    end
  end
end

-- -- Set up an autocommand to apply this to markdown files
-- vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
--   pattern = { "*.md" },
--   callback = function(ev)
--     conceal_math_delimiters(ev.buf)
--   end,
-- })
--
-- -- Ensure conceallevel is set appropriately for markdown files
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "markdown",
--   callback = function()
--     vim.wo.conceallevel = 2
--   end,
-- })

-- Add custom directive to conceal entire LaTeX delimiter lines
-- vim.treesitter.query.add_directive("latex-line-conceal!", function(match, _, bufnr, _, metadata)
--   local id = match.id
--   local node = match[id]
--   local start_row, _, end_row, _ = node:range()
--
--   -- Get the entire line content
--   local line_content = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
--
--   -- Set up for concealing the entire line
--   if not metadata[id] then
--     metadata[id] = {}
--   end
--   if not metadata[id].range then
--     metadata[id].range = { node:range() }
--   end
--
--   -- Extend concealment to cover the entire line
--   metadata[id].range[2] = 0 -- Column start at beginning
--   metadata[id].range[4] = #line_content -- Column end at end of line
-- end, true)
-- Script para convertir set-pairs! a múltiples directivas #set!
-- local function process_highlights()
--   local input_file = vim.fn.expand("~/.local/share/nvim/lazy/nvim-treesitter/queries/latex/highlights.scm.template")
--   local output_file = vim.fn.expand("~/.local/share/nvim/lazy/nvim-treesitter/queries/latex/highlights.scm")
--
--   local content = {}
--   local in_set_pairs = false
--   local capture = ""
--   local pairs = {}
--
--   for line in io.lines(input_file) do
--     if line:match("#set%-pairs!%s+@%w+%s+%w+") then
--       -- Empieza a capturar un bloque set-pairs!
--       in_set_pairs = true
--       capture = line:match("#set%-pairs!%s+(@%w+)%s+(%w+)")
--       pairs = {}
--     elseif in_set_pairs and line:match('"[^"]+"[^"]*"[^"]+"') then
--       -- Captura cada par de concealment
--       local key, value = line:match('"([^"]+)"%s+"([^"]+)"')
--       if key and value then
--         table.insert(pairs, { key, value })
--       end
--     elseif in_set_pairs and line:match("%)") then
--       -- Fin del bloque set-pairs, genera los set! individuales
--       in_set_pairs = false
--       for _, pair in ipairs(pairs) do
--         table.insert(content, string.format('(#set! %s "conceal" "%s" "%s")', capture, pair[1], pair[2]))
--       end
--     elseif not in_set_pairs then
--       -- Líneas normales fuera de los bloques set-pairs!
--       table.insert(content, line)
--     end
--   end
--
--   -- Escribir el archivo procesado
--   local file = io.open(output_file, "w")
--   if file then
--     file:write(table.concat(content, "\n"))
--     file:close()
--   end
-- end
--
-- process_highlights()
-- md_hl.get_md_hl()

autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.api.nvim_buf_set_keymap(0, "n", "q", "<cmd>q<cr>", { noremap = true, silent = true })
  end,
})

-- 函数：折叠 \title 之上的所有内容
local function fold_above_title()
  -- 保存当前光标位置
  local save_cursor = vim.fn.getcurpos()

  -- 移动到文件开头
  vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- {row, col}, 1-indexed for row, 0-indexed for col

  -- 搜索 \title，不回绕 ('W')
  -- vim.fn.search returns the line number if found, or 0 if not found
  local title_line = vim.fn.search("\\\\title", "W")

  if title_line > 0 then
    -- 如果 \title 不在第一行
    if title_line > 1 then
      -- 要折叠的最后一行是 \title 上一行
      local target_fold_line = title_line - 1
      -- 执行折叠命令：从第1行到 target_fold_line
      -- 使用 vim.cmd 来执行 Ex 命令
      vim.cmd("1," .. target_fold_line .. "fold")
    end
  else
    -- 如果未找到 \title，则发出通知
    vim.notify("未找到 \\title", vim.log.levels.WARN)
  end

  -- 恢复光标位置
  vim.fn.setpos(".", save_cursor)
end

-- 创建一个用户命令 :FoldAboveTitle 来调用这个 Lua 函数
vim.api.nvim_create_user_command("FoldAboveTitle", fold_above_title, {
  nargs = 0, -- 命令不接受参数
  desc = "折叠 \\title 之前的所有内容",
})
