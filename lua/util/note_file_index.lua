local M = {}

local regex = {
  setex_line_header = "^%-%-%-%-*",
  setex_equals_header = "^====*",
  atx_header = "^#",
  unordered_list = "^%s*[%*%-%+]",
  ordered_list = "^%s*%d+[%)%.]",
}
local should_run_callback = false
local function find_header_or_list(line_num)
  local line_count = vim.api.nvim_buf_line_count(0)

  if line_num < 1 or line_num > line_count then
    -- Tried to find above top or below bottom
    -- Returns nil as if it didn't find anything
    return nil
  end

  -- Special logic to check if the line below is a setex marker, meaning the line passed
  -- is the top of the header
  local line = vim.fn.getline(line_num)
  local setex_line = vim.fn.getline(line_num + 1)
  if setex_line:match(regex.setex_equals_header) and not line:match("^$") then
    return { line = line_num, type = "setex_equals_header" }
  elseif setex_line:match(regex.setex_line_header) and not line:match("^$") then
    return { line = line_num, type = "setex_line_header" }
  end

  while line_num > 0 and line_num <= line_count do
    local line = vim.fn.getline(line_num)
    for name, pattern in pairs(regex) do
      if line:match(pattern) then
        if name == "setex_equals_header" or name == "setex_line_header" then
          if vim.fn.getline(line_num - 1):match("^$") then
            -- Not actually a setex header without a title
            break
          end
          line_num = line_num - 1
        end

        return { line = line_num, type = name }
      end
    end

    line_num = line_num - 1
  end
end

-- Given a the line of a bullet, returns a table of properties of the bullet.
local function parse_bullet(bullet_line)
  local line = vim.fn.getline(bullet_line)
  local bullet = {}

  -- Find what sort of bullet it is (*,-,+ ordered)
  bullet.indent, bullet.marker, bullet.trailing_indent, bullet.text = line:match("^(%s*)([%*%-%+])(%s+)(.*)")
  if not bullet.marker then
    -- Check ordered
    bullet.indent, bullet.marker, bullet.delimiter, bullet.trailing_indent, bullet.text =
      line:match("^(%s*)(%d+)([%)%.])(%s+)(.*)")
    bullet.type = "ordered_list"
  else
    bullet.delimiter = ""
    bullet.type = "unordered_list"
  end

  -- Didn't find marker at all, must not be a bullet
  if not bullet.marker then
    return nil
  end

  -- Test for checkbox, too hard to do above
  local checkbox = bullet.text:match("^%[([%sx])%]")
  if checkbox then
    bullet.checkbox = {}
    bullet.checkbox.checked = checkbox == "x" and true or false
    bullet.text = bullet.text:sub(5)
  end

  bullet.indent = #bullet.indent
  bullet.trailing_indent = #bullet.trailing_indent
  bullet.start = bullet_line

  -- Iterate down to find bottom of bullet and if it has children

  local line_count = vim.api.nvim_buf_line_count(0)
  local iter = bullet.start + 1 -- start one past end if at last line [1]
  while true do
    local indent = vim.fn.indent(iter)

    -- Test for children
    -- test for having children and larger indent first to prevent regex
    if not bullet.has_children and indent >= bullet.indent + vim.o.shiftwidth then
      local child = vim.fn.getline(iter)
      if child:match(regex.unordered_list) or child:match(regex.ordered_list) then
        bullet.has_children = true
      end
    end

    -- Test for end of bullet
    if indent <= bullet.indent then
      bullet.stop = iter - 1
      break
    end

    -- Last line will always be end
    if iter >= line_count then
      -- [1] checked for being above here
      bullet.stop = line_count
      break
    end

    iter = iter + 1
  end

  local function newline(insert_line, folded)
    local bullet_above, bullet_below

    if folded then
      bullet_above = parse_bullet(vim.fn.foldclosed(insert_line))
      bullet_below = parse_bullet(insert_line + 1)
    else
      bullet_above = parse_bullet(insert_line)
      bullet_below = parse_bullet(insert_line + 1)
    end

    if bullet_above then
      -- remove bullet and insert new line if the bullet is empty
      if #bullet_above.text == 0 then
        vim.cmd("startinsert")
        vim.api.nvim_buf_set_lines(0, insert_line - 1, insert_line, true, { "", "" })
        vim.api.nvim_win_set_cursor(0, { insert_line + 1, 0 })
        return
      end

      -- Use the properties of the bullet below if its indent is higher than the one above.
      local bullet
      if bullet_below and bullet_below.indent > bullet_above.indent then
        bullet = bullet_below
      else
        bullet = bullet_above
      end

      local indent = string.rep(" ", bullet.indent)
      local marker = bullet.marker
      local delimiter = bullet.delimiter
      local trailing_indent = string.rep(" ", bullet.trailing_indent)

      -- Use checkbox of the above bullet if they are equally indented
      local checkbox
      if bullet_above and bullet_below and bullet_above.indent == bullet_below.indent then
        checkbox = bullet_above.checkbox and "[ ] " or ""
      else
        checkbox = bullet.checkbox and "[ ] " or ""
      end

      if tonumber(marker) then
        marker = marker + 1
        -- TODO: reoder list if there are other bullets below
        --other_bullets = parse_list(bullet.start)
        --for _, bullet_line in pairs(other_bullets) do
        --    local incremented = vim.fn.getline(bullet_line):sub
      end

      local new_line = indent .. marker .. delimiter .. trailing_indent .. checkbox
      vim.cmd("startinsert")
      vim.fn.append(insert_line, new_line)
      vim.api.nvim_win_set_cursor(0, { insert_line + 1, 1000000 })
      should_run_callback = true
    elseif folded then
      vim.cmd("startinsert")
      vim.fn.append(insert_line, "")
      vim.api.nvim_win_set_cursor(0, { insert_line + 1, 0 })
    else
      -- Insert line normally
      vim.cmd("startinsert")
      vim.fn.append(insert_line, "")
      vim.api.nvim_win_set_cursor(0, { insert_line + 1, 1000000 })
    end
  end

  -- Try to find parent bullet
  -- Might be too intensive to do the recursive if too deep in the tree
  if bullet.indent > 0 then
    local section = find_header_or_list(bullet.start - 1)
    while true do
      if not section or not section.type or not section.type:match("list") then
        -- Can't find parent even though there is supposed to be one
        break
      elseif vim.fn.indent(section.line) < bullet.indent then
        -- Found parent at lower indentation level
        bullet.parent = parse_bullet(section.line)
        break
      else
        -- Sibling bullet, find next bullet
        section = find_header_or_list(section.line - 1)
      end
    end
  end
  return bullet
end

local function newline(insert_line, folded)
  local bullet_above, bullet_below

  if folded then
    bullet_above = parse_bullet(vim.fn.foldclosed(insert_line))
    bullet_below = parse_bullet(insert_line + 1)
  else
    bullet_above = parse_bullet(insert_line)
    bullet_below = parse_bullet(insert_line + 1)
  end

  if bullet_above then
    -- remove bullet and insert new line if the bullet is empty
    if #bullet_above.text == 0 then
      vim.cmd("startinsert")
      vim.api.nvim_buf_set_lines(0, insert_line - 1, insert_line, true, { "", "" })
      vim.api.nvim_win_set_cursor(0, { insert_line + 1, 0 })
      return
    end

    -- Use the properties of the bullet below if its indent is higher than the one above.
    local bullet
    if bullet_below and bullet_below.indent > bullet_above.indent then
      bullet = bullet_below
    else
      bullet = bullet_above
    end

    local indent = string.rep(" ", bullet.indent)
    local marker = bullet.marker
    local delimiter = bullet.delimiter
    local trailing_indent = string.rep(" ", bullet.trailing_indent)

    -- Use checkbox of the above bullet if they are equally indented
    local checkbox
    if bullet_above and bullet_below and bullet_above.indent == bullet_below.indent then
      checkbox = bullet_above.checkbox and "[ ] " or ""
    else
      checkbox = bullet.checkbox and "[ ] " or ""
    end

    if tonumber(marker) then
      marker = marker + 1
      -- TODO: reoder list if there are other bullets below
      --other_bullets = parse_list(bullet.start)
      --for _, bullet_line in pairs(other_bullets) do
      --    local incremented = vim.fn.getline(bullet_line):sub
    end

    local new_line = indent .. marker .. delimiter .. trailing_indent .. checkbox
    vim.cmd("startinsert")
    vim.fn.append(insert_line, new_line)
    vim.api.nvim_win_set_cursor(0, { insert_line + 1, 1000000 })
    should_run_callback = true
  elseif folded then
    vim.cmd("startinsert")
    vim.fn.append(insert_line, "")
    vim.api.nvim_win_set_cursor(0, { insert_line + 1, 0 })
  else
    -- Insert line normally
    vim.cmd("startinsert")
    vim.fn.append(insert_line, "")
    vim.api.nvim_win_set_cursor(0, { insert_line + 1, 1000000 })
  end
end

function M.new_line_below()
  local insert_line = vim.fn.line(".")
  local folded

  local bullet = parse_bullet(insert_line)

  if vim.fn.mode() == "i" then
    local column = vim.api.nvim_win_get_cursor(0)[2] + 1
    local line = vim.api.nvim_get_current_line()

    -- Normal return if in the middle of a line, or there is no bullet
    if column < #line or not bullet then
      key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
      vim.api.nvim_feedkeys(key, "n", true)
      return
    end
  else
    if vim.fn.foldclosed(".") > 0 then
      insert_line = vim.fn.foldclosedend(".")
      folded = true
    elseif not bullet then
      vim.api.nvim_feedkeys("o", "n", true)
      return
    end
  end

  newline(insert_line, folded)
end

function M.new_line_above()
  local insert_line = vim.fn.line(".")
  local folded

  local bullet = parse_bullet(insert_line)

  if vim.fn.mode() == "i" then
    local column = vim.api.nvim_win_get_cursor(0)[2] + 1
    local line = vim.api.nvim_get_current_line()

    -- Normal return if in the middle of a line, or there is no bullet
    if column < #line or not bullet then
      key = vim.api.nvim_replace_termcodes("<CR><Up>", true, false, true)
      vim.api.nvim_feedkeys(key, "n", true)
      return
    end
  else
    if vim.fn.foldclosed(".") > 0 then
      insert_line = vim.fn.foldclosed(".")
      folded = true
    elseif not bullet then
      vim.api.nvim_feedkeys("O", "n", true)
      return
    end
  end

  newline(insert_line - 1, folded)
end

return M
