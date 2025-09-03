local M = {}

-- Namespace for quickfix highlighting
M.ns = vim.api.nvim_create_namespace("typst_qf")

-- User option: show icons in quickfix messages
M.use_icons = true

-- Define (or link) highlight groups once
local function ensure_hl()
  local function link_or_define(group, fallback, spec)
    if fallback and vim.fn.hlexists(fallback) == 1 then
      vim.api.nvim_set_hl(0, group, { link = fallback })
    else
      vim.api.nvim_set_hl(0, group, spec)
    end
  end

  link_or_define("TypstQFError", "DiagnosticError", { fg = "#ff5555" })
  link_or_define("TypstQFWarning", "DiagnosticWarn", { fg = "#ffaf00" })
  link_or_define("TypstQFHint", "DiagnosticHint", { fg = "#56b6c2" })
  link_or_define("TypstQFHelp", "DiagnosticInformation", { fg = "#61afef" })
end

-- Parse a group of output lines, return quickfix list
local function parse_lines(lines)
  local qf = {}
  local current_error_msg = nil
  local pending_extra = {} -- accumulate hint/help/warning

  local function decorate(text)
    if not M.use_icons then
      return text
    end
    -- Only add icons to leading keywords to keep find() simpler later
    text = text:gsub("^error:", "error:"):gsub("^warning:", "warning:"):gsub("^help:", "help:"):gsub("^hint:", " hint:")
    -- Also replace internal separators (extra parts)
    text = text:gsub(" hint:", "hint:"):gsub(" help:", "help:"):gsub(" warning:", "warning:"):gsub(" error:", "error:")
    return text
  end

  local function push(file, lnum, col)
    local text = current_error_msg or "error:"
    if #pending_extra > 0 then
      text = text .. " | " .. table.concat(pending_extra, " | ")
    end
    text = decorate(text)
    table.insert(qf, {
      filename = file,
      lnum = tonumber(lnum),
      col = tonumber(col),
      text = text,
      type = "E", -- we keep type=E; could refine later
    })
    pending_extra = {}
  end

  for _, l in ipairs(lines) do
    local err = l:match("^error:%s*(.+)")
    if err then
      current_error_msg = "error: " .. err
      pending_extra = {}
    else
      local hint = l:match("^%s*= hint:%s*(.+)")
      if hint then
        table.insert(pending_extra, "hint: " .. hint)
      else
        local help = l:match("^help:%s*(.+)")
        if help then
          table.insert(pending_extra, "help: " .. help)
        else
          local warn = l:match("^warning:%s*(.+)")
          if warn then
            table.insert(pending_extra, "warning: " .. warn)
          else
            -- Match position line: e.g. "   ┌─ test.typ:14:18"
            local file, ln, col = l:match("┌─%s*(%S+):(%d+):(%d+)")
            if file then
              push(file, ln, col)
            else
              -- Fallback without border
              file, ln, col = l:match("^%s*(%S+):(%d+):(%d+)")
              if file and current_error_msg then
                push(file, ln, col)
              end
            end
          end
        end
      end
    end
  end
  return qf
end

-- Highlight keywords (error/help/hint/warning) in the quickfix buffer
function M.apply_qf_highlight()
  ensure_hl()
  local info = vim.fn.getqflist({ winid = 1 })
  local winid = info.winid
  if winid == 0 then
    return
  end
  local buf = vim.api.nvim_win_get_buf(winid)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if vim.bo[buf].filetype ~= "qf" then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  -- Pattern map (lower-case compare) -> highlight group
  local map = {
    { word = "error", hl = "TypstQFError" },
    { word = "warning", hl = "TypstQFWarning" },
    { word = "hint", hl = "TypstQFHint" },
    { word = "help", hl = "TypstQFHelp" },
  }

  for i, line in ipairs(lines) do
    local lower = line:lower()
    for _, m in ipairs(map) do
      local s, e = lower:find(m.word, 1, true)
      if s then
        -- Convert to 0-based column indices
        vim.api.nvim_buf_add_highlight(buf, M.ns, m.hl, i - 1, s - 1, e)
        -- If you prefer highlighting only the keyword (no trailing message),
        -- you can break here after the first match.
      end
    end
  end
end

-- Run typst compile asynchronously, fill quickfix, then highlight
function M.build_current(opts)
  opts = opts or {}
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then
    vim.notify("No file name (unsaved buffer?)", vim.log.levels.ERROR)
    return
  end
  local out = opts.out or ""
  local cmd = { "typst", "compile", file }
  if out ~= "" then
    table.insert(cmd, out)
  end

  local stdout_data, stderr_data = {}, {}

  local function on_exit(_, code)
    local lines = {}
    vim.list_extend(lines, stdout_data)
    vim.list_extend(lines, stderr_data)

    local qf = parse_lines(lines)
    if #qf == 0 and code ~= 0 then
      table.insert(qf, {
        filename = file,
        lnum = 1,
        col = 1,
        text = "[raw typst output]\n" .. table.concat(lines, "\n"),
        type = "E",
      })
    end

    vim.schedule(function()
      vim.fn.setqflist({}, "r", {
        title = "Typst Build",
        items = qf,
      })
      if #qf > 0 then
        vim.cmd("copen")
      end
      -- Apply highlight after quickfix opens
      vim.schedule(function()
        M.apply_qf_highlight()
      end)

      if code == 0 then
        vim.notify("Typst build succeeded", vim.log.levels.INFO)
      else
        vim.notify("Typst build finished with errors (code=" .. code .. ")", vim.log.levels.WARN)
      end
    end)
  end

  vim.notify("Running: " .. table.concat(cmd, " "))

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      for _, l in ipairs(data) do
        if l and l ~= "" then
          table.insert(stdout_data, l)
        end
      end
    end,
    on_stderr = function(_, data)
      for _, l in ipairs(data) do
        if l and l ~= "" then
          table.insert(stderr_data, l)
        end
      end
    end,
    on_exit = on_exit,
  })
end

-- Optional: re-apply highlight when quickfix window is (re)entered
if not M._autocmd then
  M._autocmd = vim.api.nvim_create_autocmd({ "BufWinEnter", "WinScrolled", "CursorHold" }, {
    callback = function()
      local ft = vim.bo.filetype
      if ft == "qf" then
        pcall(M.apply_qf_highlight)
      end
    end,
  })
end

return M
