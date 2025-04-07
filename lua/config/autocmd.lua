local autocmd = vim.api.nvim_create_autocmd
local function mkdMath()
  vim.cmd([[
      set foldmethod=marker
      syn include @tex /Users/pxwg-dogggie/.local/share/nvim/lazy/vimtex/syntax/tex.vim

syn region mkdMath
      \ start="\$" end="\$"
      \ skip="\\\$"
      \ containedin=@markdownTop
      \ contains=@tex
      \ keepend
      \ oneline

syn region mkdMath
      \ start="\$\$" end="\$\$"
      \ skip="\\\$"
      \ containedin=@markdownTop
      \ contains=@tex
      \ keepend]])
end

local function apply_math_highlight(bufnr)
  if vim.bo[bufnr].filetype ~= "markdown" then
    return
  end
  vim.schedule(function()
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd([[
        syn clear mkdMath
        syn cluster texMathZones remove=mkdMath
      ]])
      mkdMath()
      vim.cmd([[
        doautoall Syntax
        redraw!
      ]])
    end)
  end)
end

local function mdHL()
  vim.cmd([[
      syn match mkdTaskItem /\v^\s*-\s*\[\s*[x]\s*\]/
      highlight link mkdTaskItem RenderMarkdownTodo
      syn match mkdItemDot /^\s*\*/
      highlight link mkdItemDot @markup.list

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
end

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

autocmd("FileType", {
  pattern = { "copilot-chat", "markdown" },
  callback = function()
    vim.cmd("SidenoteRestoreAll")
    -- mkdMath()
  end,
})

autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.md", "*.copilot-chat" },
  callback = function()
    mkdMath()
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
