local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "mitex" })
end

local function typst_bin()
  return vim.g.mitex_typst_bin or "typst"
end

local function mitex_package()
  return vim.g.mitex_typst_package or "@preview/mitex:0.2.7"
end

local function typst_string(value)
  value = value:gsub("\\", "\\\\")
  value = value:gsub('"', '\\"')
  value = value:gsub("\r", "\\r")
  value = value:gsub("\n", "\\n")
  value = value:gsub("\t", "\\t")
  return '"' .. value .. '"'
end

local function system(cmd, input)
  local nvim_system = vim.system
  if type(nvim_system) == "function" then
    local result = nvim_system(cmd, { stdin = input, text = true }):wait()
    return result.code, result.stdout or "", result.stderr or ""
  end

  local output = vim.fn.system(cmd, input)
  return vim.v.shell_error, output, ""
end

local function mitex_convert(latex)
  local input = table.concat({
    '#import "' .. mitex_package() .. '": mitex-convert',
    "#metadata(mitex-convert(" .. typst_string(latex) .. ")) <mitex-conv>",
  }, "\n")

  local code, stdout, stderr = system({ typst_bin(), "query", "-", "<mitex-conv>", "--field", "value", "--one" }, input)

  if code ~= 0 then
    return nil, vim.trim(stderr ~= "" and stderr or stdout)
  end

  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok or type(decoded) ~= "string" then
    return nil, "could not decode typst query output: " .. stdout
  end

  return decoded, nil
end

local function trim_blank_edges(lines)
  while #lines > 0 and lines[1]:match("^%s*$") do
    table.remove(lines, 1)
  end
  while #lines > 0 and lines[#lines]:match("^%s*$") do
    table.remove(lines)
  end
  return lines
end

local function dedent_lines(lines)
  local min_indent = nil
  for _, line in ipairs(lines) do
    if line:match("%S") then
      local indent = #(line:match("^%s*") or "")
      min_indent = min_indent and math.min(min_indent, indent) or indent
    end
  end

  if not min_indent or min_indent == 0 then
    return lines
  end

  local out = {}
  for _, line in ipairs(lines) do
    out[#out + 1] = line:sub(min_indent + 1)
  end
  return out
end

local function extract_latex(lines, first, last)
  local raw = {}
  for i = first, last do
    raw[#raw + 1] = lines[i]
  end
  raw = trim_blank_edges(dedent_lines(trim_blank_edges(raw)))
  return table.concat(raw, "\n")
end

local function split_lines(value)
  value = value:gsub("\r\n", "\n"):gsub("\r", "\n")
  local lines = {}
  for line in (value .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  return trim_blank_edges(lines)
end

local function find_blocks(lines)
  local blocks = {}
  local i = 1

  while i <= #lines do
    local indent = lines[i]:match("^(%s*)#mitex%s*%(%s*$")
    if not indent then
      i = i + 1
    else
      local open_line, fence
      local j = i + 1
      while j <= #lines do
        fence = lines[j]:match("^%s*(```+)%s*$")
        if fence then
          open_line = j
          break
        end
        if lines[j]:match("^%s*%)%s*,?%s*$") then
          break
        end
        j = j + 1
      end

      if not open_line then
        i = i + 1
      else
        local close_line
        j = open_line + 1
        while j <= #lines do
          if lines[j]:match("^%s*" .. fence .. "%s*,?%s*$") then
            close_line = j
            break
          end
          j = j + 1
        end

        if not close_line then
          i = open_line + 1
        else
          local end_line
          j = close_line + 1
          while j <= #lines do
            if lines[j]:match("^%s*%)%s*,?%s*$") then
              end_line = j
              break
            end
            j = j + 1
          end

          if not end_line then
            i = close_line + 1
          else
            blocks[#blocks + 1] = {
              start = i,
              finish = end_line,
              raw_start = open_line + 1,
              raw_finish = close_line - 1,
              indent = indent,
            }
            i = end_line + 1
          end
        end
      end
    end
  end

  return blocks
end

local function replacement_lines(block, converted)
  local out = { block.indent .. "$" }
  for _, line in ipairs(split_lines(converted)) do
    out[#out + 1] = block.indent .. "  " .. line
  end
  out[#out + 1] = block.indent .. "$"
  return out
end

local function convert_block_at(bufnr, block, lines)
  local latex = extract_latex(lines, block.raw_start, block.raw_finish)
  local converted, err = mitex_convert(latex)
  if not converted then
    return false, err
  end

  vim.api.nvim_buf_set_lines(bufnr, block.start - 1, block.finish, false, replacement_lines(block, converted))
  return true, nil
end

function M.convert_block()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  for _, block in ipairs(find_blocks(lines)) do
    if block.start <= cursor_line and cursor_line <= block.finish then
      local ok, err = convert_block_at(bufnr, block, lines)
      if ok then
        notify("converted #mitex block at line " .. block.start)
      else
        notify("line " .. block.start .. ": " .. err, vim.log.levels.ERROR)
      end
      return
    end
  end

  notify("cursor is not inside a supported #mitex raw block", vim.log.levels.WARN)
end

function M.convert_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local blocks = find_blocks(lines)

  local converted = 0
  local failed = {}

  for idx = #blocks, 1, -1 do
    local block = assert(blocks[idx])
    local ok, err = convert_block_at(bufnr, block, lines)
    if ok then
      converted = converted + 1
    else
      failed[#failed + 1] = block.start .. ": " .. err
    end
  end

  if #failed == 0 then
    notify("converted " .. converted .. " #mitex block(s)")
  else
    notify("converted " .. converted .. " #mitex block(s); failed " .. #failed, vim.log.levels.WARN)
    notify(table.concat(failed, "\n"), vim.log.levels.ERROR)
  end
end

local actions = {
  block = M.convert_block,
  buffer = M.convert_buffer,
}

local function complete_action(arg_lead)
  local matches = {}
  for action, _ in pairs(actions) do
    if action:find("^" .. vim.pesc(arg_lead)) then
      matches[#matches + 1] = action
    end
  end
  table.sort(matches)
  return matches
end

vim.api.nvim_create_user_command("Mitex", function(opts)
  local action = actions[opts.args]
  if not action then
    notify("usage: :Mitex {block|buffer}", vim.log.levels.ERROR)
    return
  end
  action()
end, {
  nargs = 1,
  complete = complete_action,
})

return M
