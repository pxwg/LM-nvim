local M = {}

local function executable(name)
  return vim.fn.executable(name) == 1
end

local function ensure_dir(path)
  vim.fn.mkdir(path, "p")
end

local function shell_result(args)
  local result = vim.system(args, { text = true }):wait()
  if result.code ~= 0 then
    return nil, vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
  end

  return result.stdout or ""
end

local function normalize_positions(a, b)
  if a.line > b.line or (a.line == b.line and a.col > b.col) then
    return b, a
  end

  return a, b
end

local function active_visual_mode()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    return mode
  end

  local ok, last_mode = pcall(vim.fn.visualmode)
  if ok and (last_mode == "v" or last_mode == "V" or last_mode == "\22") then
    return last_mode
  end

  return "v"
end

local function range_from_visual()
  local mode = active_visual_mode()
  local mode_now = vim.fn.mode()
  local start_pos
  local end_pos

  if mode_now == "v" or mode_now == "V" or mode_now == "\22" then
    start_pos = vim.fn.getpos("v")
    end_pos = vim.fn.getpos(".")
  else
    start_pos = vim.fn.getpos("'<")
    end_pos = vim.fn.getpos("'>")
  end

  local start_item, end_item = normalize_positions({
    line = start_pos[2],
    col = math.max(start_pos[3], 1),
  }, {
    line = end_pos[2],
    col = math.max(end_pos[3], 1),
  })

  return {
    mode = mode,
    start_line = start_item.line,
    start_col = start_item.col,
    end_line = end_item.line,
    end_col = end_item.col,
  }
end

local function range_from_command(opts)
  local line1 = tonumber(opts and opts.line1) or vim.fn.line(".")
  local line2 = tonumber(opts and opts.line2) or line1
  if line1 > line2 then
    line1, line2 = line2, line1
  end

  return {
    mode = "V",
    start_line = line1,
    start_col = 1,
    end_line = line2,
    end_col = math.max(#vim.api.nvim_buf_get_lines(0, line2 - 1, line2, false)[1], 1),
  }
end

local function selected_text(bufnr, range)
  if range.mode == "V" then
    return table.concat(vim.api.nvim_buf_get_lines(bufnr, range.start_line - 1, range.end_line, false), "\n")
  end

  if range.mode == "\22" then
    local lines = vim.api.nvim_buf_get_lines(bufnr, range.start_line - 1, range.end_line, false)
    local out = {}
    local left = math.min(range.start_col, range.end_col)
    local right = math.max(range.start_col, range.end_col)
    for _, line in ipairs(lines) do
      table.insert(out, line:sub(left, right))
    end
    return table.concat(out, "\n")
  end

  local lines =
    vim.api.nvim_buf_get_text(bufnr, range.start_line - 1, range.start_col - 1, range.end_line - 1, range.end_col, {})
  return table.concat(lines, "\n")
end

local function parse_frame(output)
  local name, x, y, w, h = output:match("^%s*(.-),%s*(-?%d+),%s*(-?%d+),%s*(%d+),%s*(%d+)%s*$")
  if not name then
    return nil
  end

  return {
    app = name,
    x = tonumber(x),
    y = tonumber(y),
    width = tonumber(w),
    height = tonumber(h),
  }
end

local function front_window_frame()
  if vim.fn.has("mac") ~= 1 or not executable("osascript") then
    return nil, "front-window geometry requires macOS osascript"
  end

  local script = [[
tell application "System Events"
  set frontApp to first application process whose frontmost is true
  set winPos to position of front window of frontApp
  set winSize to size of front window of frontApp
  return (name of frontApp) & "," & (item 1 of winPos) & "," & (item 2 of winPos) & "," & (item 1 of winSize) & "," & (item 2 of winSize)
end tell
]]
  local output, err = shell_result({ "osascript", "-e", script })
  if not output then
    return nil, err ~= "" and err or "osascript failed to read front-window geometry"
  end

  return parse_frame(output), nil
end

local function find_kitty_window(tree, window_id)
  for _, os_window in ipairs(tree or {}) do
    for _, tab in ipairs(os_window.tabs or {}) do
      for index, window in ipairs(tab.windows or {}) do
        if window.id == window_id or window.is_self then
          return os_window, tab, window, index
        end
      end
    end
  end

  return nil
end

local function kitty_pane_grid()
  if not executable("kitty") or not vim.env.KITTY_WINDOW_ID then
    return nil
  end

  local output = shell_result({ "kitty", "@", "ls" })
  if not output then
    return nil
  end

  local ok, tree = pcall(vim.json.decode, output)
  if not ok then
    return nil
  end

  local _, tab, self_window = find_kitty_window(tree, tonumber(vim.env.KITTY_WINDOW_ID))
  if not tab or not self_window then
    return nil
  end

  local windows = tab.windows or {}
  if #windows == 1 then
    return {
      col0 = 0,
      row0 = 0,
      columns = self_window.columns,
      lines = self_window.lines,
      total_columns = self_window.columns,
      total_lines = self_window.lines,
    }
  end

  local same_lines = true
  local same_columns = true
  for _, window in ipairs(windows) do
    same_lines = same_lines and window.lines == self_window.lines
    same_columns = same_columns and window.columns == self_window.columns
  end

  if same_lines then
    local col0 = 0
    local total_columns = 0
    for _, window in ipairs(windows) do
      if window.id == self_window.id then
        col0 = total_columns
      end
      total_columns = total_columns + window.columns
    end

    return {
      col0 = col0,
      row0 = 0,
      columns = self_window.columns,
      lines = self_window.lines,
      total_columns = total_columns,
      total_lines = self_window.lines,
    }
  end

  if same_columns then
    local row0 = 0
    local total_lines = 0
    for _, window in ipairs(windows) do
      if window.id == self_window.id then
        row0 = total_lines
      end
      total_lines = total_lines + window.lines
    end

    return {
      col0 = 0,
      row0 = row0,
      columns = self_window.columns,
      lines = self_window.lines,
      total_columns = self_window.columns,
      total_lines = total_lines,
    }
  end

  return nil
end

local function cell_geometry(frame)
  local grid = kitty_pane_grid()
  if grid then
    local cell_width = frame.width / grid.total_columns
    local cell_height = frame.height / grid.total_lines
    return {
      x = frame.x + grid.col0 * cell_width,
      y = frame.y + grid.row0 * cell_height,
      width = grid.columns * cell_width,
      height = grid.lines * cell_height,
      cell_width = cell_width,
      cell_height = cell_height,
    }
  end

  return {
    x = frame.x,
    y = frame.y,
    width = frame.width,
    height = frame.height,
    cell_width = frame.width / vim.o.columns,
    cell_height = frame.height / vim.o.lines,
  }
end

local function screen_position(winid, line, col)
  local ok, pos = pcall(vim.fn.screenpos, winid, line, math.max(col, 1))
  if not ok or not pos or pos.row == 0 or pos.col == 0 then
    return nil
  end

  return pos
end

local function selection_screen_cells(winid, range)
  local win_pos = vim.fn.win_screenpos(winid)
  local win_left = win_pos[2]
  local win_right = win_left + vim.api.nvim_win_get_width(winid) - 1

  local top
  local bottom
  local left
  local right

  if range.start_line == range.end_line and range.mode ~= "V" then
    local start_pos = screen_position(winid, range.start_line, range.start_col)
    local end_pos = screen_position(winid, range.end_line, range.end_col)
    if not start_pos or not end_pos then
      return nil, "selection is not visible in the current window"
    end

    top = math.min(start_pos.row, end_pos.row)
    bottom = math.max(start_pos.row, end_pos.row)
    left = math.min(start_pos.col, end_pos.col)
    right = math.max(start_pos.endcol or start_pos.col, end_pos.endcol or end_pos.col)
  elseif range.mode == "\22" then
    local start_pos = screen_position(winid, range.start_line, range.start_col)
    local end_pos = screen_position(winid, range.end_line, range.end_col)
    if not start_pos or not end_pos then
      return nil, "selection is not visible in the current window"
    end

    top = math.min(start_pos.row, end_pos.row)
    bottom = math.max(start_pos.row, end_pos.row)
    left = math.min(start_pos.col, end_pos.col)
    right = math.max(start_pos.endcol or start_pos.col, end_pos.endcol or end_pos.col)
  else
    for line = range.start_line, range.end_line do
      local line_text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
      local line_end = math.max(#line_text, 1)
      local pos = screen_position(winid, line, line_end) or screen_position(winid, line, 1)
      if pos then
        top = top and math.min(top, pos.row) or pos.row
        bottom = bottom and math.max(bottom, pos.row) or pos.row
      end
    end

    if not top or not bottom then
      return nil, "selection is not visible in the current window"
    end

    left = win_left
    right = win_right
  end

  local padding = 1
  return {
    top = math.max(1, top - padding),
    bottom = math.min(vim.o.lines, bottom + padding),
    left = math.max(1, left - padding),
    right = math.min(vim.o.columns, right + padding),
  }
end

local function screen_rect(range)
  local frame, err = front_window_frame()
  if not frame then
    return nil, err
  end

  local cells, cells_err = selection_screen_cells(vim.api.nvim_get_current_win(), range)
  if not cells then
    return nil, cells_err
  end

  local geom = cell_geometry(frame)
  local x = geom.x + (cells.left - 1) * geom.cell_width
  local y = geom.y + (cells.top - 1) * geom.cell_height
  local width = math.max(geom.cell_width, (cells.right - cells.left + 1) * geom.cell_width)
  local height = math.max(geom.cell_height, (cells.bottom - cells.top + 1) * geom.cell_height)

  return {
    x = math.floor(x + 0.5),
    y = math.floor(y + 0.5),
    width = math.floor(width + 0.5),
    height = math.floor(height + 0.5),
  }
end

local function safe_filename(name)
  name = name ~= "" and name or "scratch"
  return name:gsub("[^%w%._%-]", "_")
end

local function capture_dir()
  local dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "selection-captures")
  ensure_dir(dir)
  return dir
end

local function capture_path(bufname)
  local stamp = os.date("%Y%m%d-%H%M%S")
  local basename = safe_filename(vim.fn.fnamemodify(bufname ~= "" and bufname or "scratch", ":t"))
  return vim.fs.joinpath(capture_dir(), stamp .. "-" .. basename .. ".png")
end

local function take_screenshot(range, image_path)
  if vim.fn.has("mac") ~= 1 or not executable("screencapture") then
    return nil, "screenshot requires macOS screencapture"
  end

  local rect, rect_err = screen_rect(range)
  if not rect then
    return nil, rect_err
  end

  vim.cmd("redraw")
  local spec = string.format("%d,%d,%d,%d", rect.x, rect.y, rect.width, rect.height)
  local result = vim.system({ "screencapture", "-x", "-R", spec, image_path }, { text = true }):wait()
  if result.code ~= 0 then
    return nil, vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
  end

  return image_path, nil
end

local function markdown_fence(text)
  local fence_len = 3
  for run in tostring(text):gmatch("`+") do
    fence_len = math.max(fence_len, #run + 1)
  end
  return string.rep("`", fence_len)
end

local function markdown_payload(meta, text)
  local fence = markdown_fence(text)
  local lines = {
    "# Neovim Selection Capture",
    "",
    "- file: `" .. meta.file .. "`",
    "- range: `L" .. meta.start_line .. ":C" .. meta.start_col .. "-L" .. meta.end_line .. ":C" .. meta.end_col .. "`",
    "- cwd: `" .. meta.cwd .. "`",
    "- filetype: `" .. meta.filetype .. "`",
    "- captured_at: `" .. meta.captured_at .. "`",
  }

  if meta.image_path then
    table.insert(lines, "- screenshot: `" .. meta.image_path .. "`")
    table.insert(lines, "")
    table.insert(lines, "![](" .. meta.image_path .. ")")
  end

  table.insert(lines, "")
  table.insert(lines, fence .. (meta.filetype ~= "" and meta.filetype or "text"))
  table.insert(lines, text)
  table.insert(lines, fence)

  return table.concat(lines, "\n")
end

local function class_literal(name)
  return string.char(194, 171) .. "class " .. name .. string.char(194, 187)
end

local function copy_to_clipboard(payload, image_path)
  vim.fn.setreg("+", payload)

  if vim.fn.has("mac") ~= 1 or not executable("osascript") then
    return true, nil
  end

  local dir = capture_dir()
  local text_path = vim.fs.joinpath(dir, "clipboard.txt")
  local script_path = vim.fs.joinpath(dir, "clipboard.applescript")
  vim.fn.writefile(vim.split(payload, "\n", { plain = true }), text_path)

  local utf8_class = class_literal("utf8")
  local png_class = class_literal("PNGf")
  local script = {
    "on run argv",
    "  set textPath to item 1 of argv",
    "  set imagePath to item 2 of argv",
    "  set payloadText to read (POSIX file textPath) as " .. utf8_class,
    '  if imagePath is not "" then',
    "    set imageData to read (POSIX file imagePath) as " .. png_class,
    "    set the clipboard to {Unicode text:payloadText, "
      .. utf8_class
      .. ":payloadText, "
      .. png_class
      .. ":imageData}",
    "  else",
    "    set the clipboard to payloadText",
    "  end if",
    "end run",
  }
  vim.fn.writefile(script, script_path)

  local result = vim.system({ "osascript", script_path, text_path, image_path or "" }, { text = true }):wait()
  if result.code ~= 0 then
    return false, vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
  end

  return true, nil
end

function M.capture(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local range = opts.line1 and opts.line2 and range_from_command(opts) or range_from_visual()
  if range.start_line <= 0 or range.end_line <= 0 then
    vim.notify("No visual selection found.", vim.log.levels.WARN)
    return
  end

  local text = selected_text(bufnr, range)
  if text == "" then
    vim.notify("Selection is empty.", vim.log.levels.WARN)
    return
  end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local image_path = capture_path(bufname)
  local screenshot_path, screenshot_err = take_screenshot(range, image_path)
  local meta = {
    file = bufname ~= "" and vim.fn.fnamemodify(bufname, ":p") or "[No Name]",
    cwd = vim.uv.cwd() or vim.fn.getcwd(),
    filetype = vim.bo[bufnr].filetype,
    start_line = range.start_line,
    start_col = range.start_col,
    end_line = range.end_line,
    end_col = range.end_col,
    captured_at = os.date("%Y-%m-%d %H:%M:%S %z"),
    image_path = screenshot_path,
  }

  local payload = markdown_payload(meta, text)
  local ok, copy_err = copy_to_clipboard(payload, screenshot_path)
  if not ok then
    vim.notify("Copied text metadata, but rich clipboard failed: " .. copy_err, vim.log.levels.WARN)
    return
  end

  if screenshot_path then
    vim.notify("Selection screenshot and metadata copied to clipboard: " .. screenshot_path, vim.log.levels.INFO)
  else
    vim.notify("Selection metadata copied; screenshot skipped: " .. tostring(screenshot_err), vim.log.levels.WARN)
  end
end

return M
