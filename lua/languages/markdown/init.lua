-- Markdown language configuration  
-- Specific autocmds, keymaps, and settings for Markdown files

local M = {}

local autocmd = vim.api.nvim_create_autocmd
local map = vim.keymap.set

M.setup = function()
  -- Markdown-specific autocmds
  autocmd("FileType", {
    pattern = { "markdown" },
    callback = function()
      -- Enable spell checking for Markdown files
      if vim.bo.buftype ~= "nofile" then
        vim.opt_local.spell = true
        vim.opt_local.spelllang = "en_us,cjk"
      end
      
      -- Set concealment for markdown math
      if vim.bo.buftype == "nofile" then
        vim.opt_local.conceallevel = 2
        vim.opt_local.concealcursor = "nc"
      end
    end,
  })

  -- Markdown file write handling  
  autocmd("BufWritePre", { 
    pattern = { "*.md", "*.html" }, 
    command = "set nowritebackup" 
  })
  autocmd("BufWritePost", { 
    pattern = { "*.md", "*.html" }, 
    command = "set writebackup" 
  })

  -- General diff option
  autocmd("OptionSet", {
    pattern = "diff",
    callback = function()
      vim.wo.wrap = true
    end,
  })

  -- Markdown-specific keymaps (only active in Markdown buffers)
  autocmd("FileType", {
    pattern = { "markdown" },
    callback = function(ev)
      local bufnr = ev.buf
      
      -- Enhanced newline behavior for Markdown
      map("i", "<CR>", function()
        return require("util.note_file_index").new_line_below()
      end, { noremap = true, silent = true, expr = true, buffer = bufnr })
      
      map("n", "o", function()
        return require("util.note_file_index").new_line_below()
      end, { buffer = bufnr })
      
      map("n", "O", function()
        return require("util.note_file_index").new_line_above()
      end, { buffer = bufnr })
      
      -- Link navigation
      map("n", "<Tab>", function()
        local success = require("util.markdown_link").goto_next_link()
        if not success then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", true)
        end
      end, { noremap = true, silent = true, buffer = bufnr })
      
      map("n", "<S-Tab>", function()
        local success = require("util.markdown_link").goto_prev_link()
        if not success then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", true)
        end
      end, { noremap = true, silent = true, buffer = bufnr })
      
      -- Link creation and navigation
      map("n", "<CR>", function()
        local line = vim.fn.getline(".")
        local col = vim.fn.col(".")
        local link_pattern = "%[.-%]%((.-)%)"
        
        local start_idx = 1
        while true do
          local link_start, link_end, link_target = string.find(line, link_pattern, start_idx)
          if not link_start then
            break
          end
          
          if link_start <= col and col <= link_end then
            if link_target:match("^https?://") then
              vim.fn.jobstart("open " .. vim.fn.shellescape(link_target))
            else
              local file_path = link_target
              if not file_path:match("^[/~]") then
                local current_dir = vim.fn.expand("%:p:h")
                file_path = current_dir .. "/" .. file_path
              end
              vim.cmd("edit " .. vim.fn.fnameescape(file_path))
            end
            break
          end
          start_idx = link_end + 1
        end
      end, { desc = "Open markdown links (file or URL)", buffer = bufnr })
      
      -- Visual selection to link conversion
      map("v", "<CR>", function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
        
        local selection_start = vim.fn.getpos("'<")
        local selection_end = vim.fn.getpos("'>")
        local start_line, start_col = selection_start[2], selection_start[3]
        local end_line, end_col = selection_end[2], selection_end[3]
        local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
        
        if #lines == 0 then
          return
        elseif #lines == 1 then
          lines[1] = string.sub(lines[1], start_col, end_col)
        else
          lines[1] = string.sub(lines[1], start_col)
          lines[#lines] = string.sub(lines[#lines], 1, end_col)
        end
        
        local selected_text = table.concat(lines, "\n")
        local filename = selected_text:gsub(" ", "_"):gsub("\\", "") .. ".md"
        local file_path = vim.fn.expand("%:p:h")
        local new_mkdn = "[" .. selected_text .. "](./" .. filename .. ")"
        local newline = vim.fn.getline("."):sub(1, start_col - 1) .. new_mkdn .. vim.fn.getline("."):sub(end_col + 1)
        vim.api.nvim_set_current_line(newline)
        local buffer_number = vim.fn.bufnr(vim.fs.joinpath(file_path, filename), true)
        vim.api.nvim_win_set_buf(0, buffer_number)
      end, { buffer = bufnr })
    end,
  })

  -- Markdown file write handling  
  autocmd("BufWritePre", { 
    pattern = { "*.md" }, 
    command = "set nowritebackup" 
  })
  autocmd("BufWritePost", { 
    pattern = { "*.md" }, 
    command = "set writebackup" 
  })
end

return M