local M = {}

local abbr_table = { "n.", "adj.", "v.", "adv.", "prep.", "pron.", "conj.", "interj." }

local function is_abbr(text, pos)
  for _, abbr in ipairs(abbr_table) do
    if text:sub(pos, pos + #abbr - 1) == abbr and text:byte(pos - 1) == 32 then
      return true
    end
  end
  return false
end

-- Extract word-definition pairs from lines starting with * or -
function M.extract_words()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local results = {}

  for _, line in ipairs(lines) do
    -- Check if line starts with * or -
    if line:match("^%s*[%*%-]") then
      -- Remove leading bullet point and whitespace
      local content = line:gsub("^%s*[%*%-]%s*", ""):gsub("*", ""):gsub("_", ""):gsub("=", "")

      -- Case with "+" for word combinations
      if content:match("%+") then
        -- Split by "+"
        local parts = vim.split(content, "+", { trimempty = true })
        local first_part = vim.trim(parts[1])
        local second_part = vim.trim(parts[2] or "")

        -- Extract first word and definition
        local first_word, first_def = M.extract_word_def_pair(first_part)
        if first_word and first_def then
          table.insert(results, { first_word, first_def })
        end

        -- Extract combined form if it exists
        if second_part ~= "" then
          local second_word, second_def = M.extract_word_def_pair(second_part)
          if second_word and second_def then
            -- Combine words
            local combined_word = first_word .. " " .. second_word
            table.insert(results, { combined_word, second_def })
          end
        end
      else
        -- Handle basic case or multiple definitions
        local pairs = M.extract_multiple_pairs(content)
        -- print(vim.inspect(pairs))
        for _, pair in ipairs(pairs) do
          table.insert(results, pair)
        end
      end
    end
  end

  vim.notify("Get " .. #results .. " words", vim.log.levels.INFO, { title = "Note" })
  return results
end

-- Extract a single word-definition pair from text
function M.extract_word_def_pair(text)
  -- Find the boundary between English and Chinese
  -- Look for the first Chinese character
  local english, chinese

  -- Find the first non-ASCII character as the boundary
  local i = 1
  while i <= #text do
    local b = string.byte(text, i)
    if b > 127 then
      english = vim.trim(text:sub(1, i - 1))
      chinese = vim.trim(text:sub(i))
      break
    end
    i = i + 1
  end
  if not chinese then
    english = vim.trim(text)
  end

  return english, chinese
end

-- Extract multiple word-definition pairs from a single line
function M.extract_multiple_pairs(text)
  local pairs = {}
  local pos = 1
  local len = #text

  while pos <= len do
    -- Find start of an English word/phrase
    while pos <= len and text:byte(pos) <= 32 do
      pos = pos + 1
    end

    if pos > len then
      break
    end

    -- Extract English part (stopping at first Chinese character)
    local word_start = pos

    while
      pos <= len
      and text:byte(pos) <= 127
      and text:byte(pos) ~= 46
      and text:byte(pos) ~= 41
      and text:byte(pos) ~= 40
      and is_abbr(text, pos) == false
    do
      pos = pos + 1
    end

    local word = vim.trim(text:sub(word_start, pos - 1))

    -- Extract Chinese definition (including all non-English characters until
    -- we find a clear boundary to a new English word)
    local def_start = pos

    -- clear boundary to a new English word i.e the boundary of definition (space followed by ASCII letter)
    while pos <= len do
      while pos <= len and text:byte(pos) == 47 do
        pos = pos + 1
      end

      if pos < len and text:byte(pos) == 40 and text:byte(pos + 1) ~= 32 then
        pos = pos + 1
      elseif
        pos < len
        and text:byte(pos) <= 32
        and text:byte(pos + 1) > 32
        and text:byte(pos) <= 127
        and text:byte(pos + 1) <= 127
      then
        break
      else
        pos = pos + 1
      end

      while pos <= len and text:byte(pos) == 32 and text:byte(pos + 1) > 127 do
        pos = pos + 1
      end
    end

    local def = vim.trim(text:sub(def_start, pos - 1))

    if word ~= "" and def ~= "" then
      table.insert(pairs, { word, def })
    end
  end

  return pairs
end

-- Format and display results in a quickfix window
function M.display_results()
  local pairs = M.extract_words()
  local source_bufnr = vim.api.nvim_get_current_buf()

  -- Create a new scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "note_eng_words"
  vim.api.nvim_buf_set_name(buf, "English Words")

  -- Populate buffer with word pairs
  local lines = {}
  for _, pair in ipairs(pairs) do
    table.insert(lines, string.format("%s | %s", pair[1], pair[2]))
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Open the buffer in a split window
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)

  -- Set up syntax highlighting for the buffer
  vim.cmd([[
    syntax match NoteEngWord "^[^|]*" contained
    syntax match NoteEngDefinition " | .*$" contained
    syntax region NoteEngLine start=/^/ end=/$/ contains=NoteEngWord,NoteEngDefinition
    highlight NoteEngWord guifg=Red gui=bold
    highlight NoteEngDefinition guifg=NONE gui=NONE
  ]])

  -- Helper function to find and optionally highlight a word in source buffer
  local ns_id = vim.api.nvim_create_namespace("note_eng_words_highlight")
  local highlight_group = "IncSearch"
  local last_match_id = nil

  local function find_word_in_source(word, should_highlight)
    local clean_word = word:gsub("[%*_=%[%]%(%)%{%}]", "")

    -- Find a window displaying the source buffer
    local win_id = nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == source_bufnr then
        win_id = win
        break
      end
    end

    if not win_id then
      return nil
    end

    -- Save current window
    local current_win = vim.api.nvim_get_current_win()

    -- Switch to source window temporarily
    vim.api.nvim_set_current_win(win_id)

    -- Clear previous highlight if any
    if should_highlight then
      vim.api.nvim_buf_clear_namespace(source_bufnr, ns_id, 0, -1)
    end

    -- Find the word
    local pattern = "\\<" .. vim.fn.escape(clean_word, "\\") .. "\\>"
    local line_num = vim.fn.search(pattern, "nw")

    if line_num > 0 and should_highlight then
      -- Ensure the line is visible
      vim.api.nvim_win_set_cursor(win_id, { line_num, 0 })
      vim.cmd("normal! zz") -- Center the view on the current line

      -- Add highlight
      local line_content = vim.api.nvim_buf_get_lines(source_bufnr, line_num - 1, line_num, false)[1]
      local start_col = line_content:find(clean_word) - 1
      if start_col and start_col >= 0 then
        vim.api.nvim_buf_add_highlight(
          source_bufnr,
          ns_id,
          highlight_group,
          line_num - 1,
          start_col,
          start_col + #clean_word
        )
      end
    end

    if should_highlight then
      vim.api.nvim_set_current_win(current_win)
    end

    return { win_id = win_id, line_num = line_num }
  end

  -- Add keybinding to jump to source and find word
  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
    callback = function()
      local line = vim.api.nvim_get_current_line()
      local word = vim.trim(line:match("^([^|]*)"))

      local result = find_word_in_source(word, false)

      if result then
        -- Jump to window or open a new one if needed
        if result.win_id then
          vim.api.nvim_set_current_win(result.win_id)
        else
          vim.cmd("split")
          vim.api.nvim_win_set_buf(0, source_bufnr)
        end
        vim.fn.search("\\<" .. vim.fn.escape(word:gsub("[%*_=%[%]%(%)%{%}]", ""), "\\") .. "\\>")
      end
    end,
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
    callback = function()
      vim.cmd("q")
    end,
  })

  -- Set up autocmd to highlight word in source buffer when moving cursor
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      local line = vim.api.nvim_get_current_line()
      local word = vim.trim(line:match("^([^|]*)"))

      find_word_in_source(word, true)
    end,
  })

  -- Set up autocmd to process the buffer when it's closed
  vim.api.nvim_create_autocmd("BufWinLeave", {
    buffer = buf,
    callback = function()
      vim.api.nvim_buf_clear_namespace(source_bufnr, ns_id, 0, -1)

      M.process_edited_buffer(buf)
    end,
  })
end

-- Process the modified buffer content
function M.process_edited_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local pairs = {}

  for _, line in ipairs(lines) do
    if line:match("|") then
      local parts = vim.split(line, "|", { plain = true })
      if #parts >= 2 then
        local word = vim.trim(parts[1])
        local definition = vim.trim(table.concat({ unpack(parts, 2) }, "|"))
        if word ~= "" and definition ~= "" then
          table.insert(pairs, { word, definition })
        end
      end
    end
  end

  local output = {}
  for _, pair in ipairs(pairs) do
    table.insert(output, string.format("<%s, %s>", pair[1], pair[2]))
  end

  local result = table.concat(output, ", ")

  -- Skip if no words found
  if #pairs == 0 then
    vim.notify("No valid word-definition pairs found", vim.log.levels.WARN)
    return
  end

  -- Show confirmation dialog
  local confirmation = vim.fn.input(string.format("Create Anki cards for %d words? (y/n): ", #pairs))
  if confirmation:lower() ~= "y" then
    return
  end
  vim.notify("Creating Anki cards...", vim.log.levels.INFO, { title = "Note" })

  -- local command = string.format("anki_card_creator --card %s --deck '英语课生词'", result)
  local job = require("plenary.job"):new({
    command = "anki_card_creator",
    args = { "--cards", result, "--deck", "英语课生词" },
    on_stderr = function(_, data)
      if data then
        print("Error: " .. data)
      end
    end,
    on_exit = function(_, return_val)
      if return_val == 0 then
        print("Anki cards created successfully!")
      end
    end,
  })
  job:start()
end

return M
