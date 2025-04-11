local M = {}

--- @class CopilotChat.source
--- @field bufnr number The buffer number for the source
--- @field winnr number The window number for the source
--- @field cwd fun():string Function to get the current working directory

--- Check if LSP is available for a buffer
--- @param bufnr number The buffer number to check
--- @return boolean, table|string Whether LSP is available and clients or error message
local function check_lsp_availability(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    return false, "No LSP clients attached to buffer"
  end
  return true, clients
end

--- Function to find function location using LSP
--- @param func_name string: The name of the function to find
--- @param bufnr number|nil: Optional buffer number (defaults to current buffer)
--- @param find_calls boolean|nil: If true, look for function calls instead of definitions
--- @return table|nil: Location information or nil if not found
local function find_function_location(func_name, bufnr, find_calls)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  find_calls = find_calls or false

  -- Check if LSP is available for this buffer
  local has_lsp, clients_or_error = check_lsp_availability(bufnr)
  if not has_lsp then
    vim.notify(clients_or_error, vim.log.levels.WARN)
    return nil
  end

  -- Get all document symbols from LSP
  local symbols = vim.lsp.buf_request_sync(
    bufnr,
    "textDocument/documentSymbol",
    { textDocument = vim.lsp.util.make_text_document_params(bufnr) },
    1000
  )

  if not symbols or vim.tbl_isempty(symbols) then
    return nil
  end

  -- Find the function definition or call
  local function find_symbol_by_name(items, name)
    if not items then
      return nil
    end

    for _, item in ipairs(items) do
      -- For function definitions (kinds 12=function, 6=method)
      if not find_calls and (item.kind == 12 or item.kind == 6) and item.name == name then
        return item, "definition"
      -- For function calls (kind 21)
      elseif find_calls and item.kind == 21 and item.name and item.name:match("^" .. name .. "%s*%(") then
        return item, "call"
      end

      -- Check children recursively
      if item.children then
        local result, type = find_symbol_by_name(item.children, name)
        if result then
          return result, type
        end
      end
    end
    return nil
  end

  -- Process all symbols from all clients
  local function_info, symbol_type = nil, nil
  for _, client_result in pairs(symbols) do
    if client_result.result then
      function_info, symbol_type = find_symbol_by_name(client_result.result, func_name)
      if function_info then
        break
      end
    end
  end

  if function_info then
    local filename = vim.api.nvim_buf_get_name(bufnr)
    return {
      filename = filename,
      name = function_info.name,
      type = symbol_type,
      start_line = function_info.range.start.line + 1, -- Convert to 1-based indexing
      start_char = function_info.range.start.character + 1,
      end_line = function_info.range["end"].line + 1,
      end_char = function_info.range["end"].character + 1,
    }
  end

  -- If no function calls found with LSP, try to find in text (only for calls)
  if find_calls then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for line_num, line_text in ipairs(lines) do
      local start_idx = line_text:find(func_name .. "%s*%(")
      if start_idx then
        local filename = vim.api.nvim_buf_get_name(bufnr)
        return {
          filename = filename,
          name = func_name,
          type = "call",
          start_line = line_num,
          start_char = start_idx,
          end_line = line_num,
          end_char = start_idx + #func_name,
        }
      end
    end
  end

  return nil
end

--- Parse the function input string
--- @param input string The input string to parse
--- @return string|nil filename The filename if provided
--- @return string|nil func_name The function name
local function parse_function_input(input)
  if not input or input == "" then
    return nil, nil
  end

  input = input:gsub("function_doc:", ""):gsub("`", ""):gsub(">", "")

  local filename, func_name
  if input:find(":") then
    -- With filename format
    filename, func_name = input:match("([^:]+):([^;]+)")
  else
    -- Without filename format
    func_name = input
  end

  return filename, func_name
end

--- Fetch function documentation using LSP hover
--- @param bufnr number The buffer number
--- @param func_location table The location information for the function
--- @return string The function documentation
local function fetch_function_documentation(bufnr, func_location)
  -- Try to get function documentation using LSP hover
  local hover_params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = {
      line = func_location.end_line - 1,
      character = func_location.end_char - 1,
    },
  }

  local function_text = ""
  local hover_result = vim.lsp.buf_request_sync(bufnr, "textDocument/hover", hover_params, 10000)

  if hover_result then
    for _, client_result in pairs(hover_result) do
      if client_result.result and client_result.result.contents then
        local contents = client_result.result.contents
        local doc = ""

        if type(contents) == "string" then
          doc = contents
        elseif type(contents) == "table" then
          if contents.kind == "markdown" then
            doc = contents.value
          elseif contents.value then
            doc = contents.value
          elseif #contents > 0 then
            for _, content in ipairs(contents) do
              if type(content) == "string" then
                doc = doc .. content .. "\n"
              elseif content.value then
                doc = doc .. content.value .. "\n"
              end
            end
          end
        end

        if doc ~= "" then
          function_text = "/* Documentation:\n" .. doc .. "*/\n\n"
        end
      end
    end
  end

  return function_text
end

--- Create a result table with documentation information
--- @param function_text string The function documentation text
--- @param func_name string The function name
--- @param filetype string The file type
--- @return table The result table
local function create_result(function_text, func_name, filetype)
  return {
    {
      content = function_text,
      filename = "function_" .. func_name,
      filetype = filetype,
      score = 1.0, -- High relevance
    },
  }
end

--- Retrieves LSP (Language Server Protocol) information for the given context
--- and passes it to the provided callback function.
--- @param callback function The function to call with the retrieved LSP data
--- @param source CopilotChat.source The source containing buffer and window information
--- @return nil
local function input_lsp(callback, source)
  local bufnr = source.bufnr
  --- get file name e.g. .config/nvim/lua/ai/copilot/chat.lua
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local filename = vim.fn.fnamemodify(filepath, ":p:.")

  -- Check if LSP is available for this buffer
  local has_lsp, clients_or_error = check_lsp_availability(bufnr)
  if not has_lsp then
    vim.notify(clients_or_error, vim.log.levels.WARN)
    vim.ui.input({
      prompt = "Enter [filepath:]function_name> ",
    }, callback)
    return
  end

  -- Get document symbols from LSP
  vim.lsp.buf_request(
    bufnr,
    "textDocument/documentSymbol",
    { textDocument = vim.lsp.util.make_text_document_params(bufnr) },
    function(err, result, _, _)
      if err or not result or vim.tbl_isempty(result) then
        vim.notify("Failed to get symbols from LSP: " .. (err or "No symbols found"), vim.log.levels.WARN)
        vim.ui.input({
          prompt = "Enter [filename:]function_name> ",
        }, callback)
        return
      end

      -- Find all function references in the document
      local function_calls = {}
      local seen = {}

      -- Recursive function to traverse symbol tree
      local function collect_function_calls(items)
        if not items or vim.tbl_isempty(items) then
          return
        end

        for _, item in ipairs(items) do
          -- Look for function/method calls (kind 21 for call)
          -- The exact kinds may vary by language server
          if item.kind == 21 or (item.name and item.name:match("%(.*%)")) then
            local name = item.name
            if not seen[name] then
              seen[name] = true
              table.insert(function_calls, {
                name = name,
                kind = "Function Call",
                range = item.range, -- Store the range for later use
              })
            end
          end

          -- Check children
          if item.children then
            collect_function_calls(item.children)
          end
        end
      end

      -- Process all symbols
      collect_function_calls(result)

      -- If no function calls found, try to use document text to find potential calls
      if #function_calls == 0 then
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        for line_num, line_text in ipairs(lines) do
          -- Simple pattern to detect potential function calls
          for call, start_col in line_text:gmatch("([%w_]+)%s*%(()") do
            if not seen[call] then
              seen[call] = true
              table.insert(function_calls, {
                name = call,
                kind = "Potential Call",
                range = {
                  start = { line = line_num - 1, character = start_col - #call - 1 },
                  ["end"] = { line = line_num - 1, character = start_col },
                },
              })
            end
          end
        end
      end

      -- If still no function calls found, allow manual input
      if #function_calls == 0 then
        vim.notify("No function calls found in document", vim.log.levels.INFO)
        vim.ui.input({
          prompt = "Enter function_doc:filename:function_name;line,character> ",
        }, callback)
        return
      end

      -- Sort function calls alphabetically
      table.sort(function_calls, function(a, b)
        return a.name < b.name
      end)

      -- Display function call selector
      vim.ui.select(function_calls, {
        prompt = "Select function call:",
        format_item = function(item)
          return string.format("%s (%s)", item.name, item.kind)
        end,
      }, function(choice)
        if not choice then
          callback("")
          return
        end

        local call_name = choice.name:gsub("%s*%(.*%)", "") -- Remove parameters if present

        -- Format according to the convention: function_doc:filename:function_name
        if vim.fn.filereadable(filepath) == 1 then
          callback(filename .. ":" .. call_name)
        else
          callback(call_name)
        end
      end)
    end
  )
end

--- Resolve LSP function documentation
--- @param init_func function|nil Optional initialization function
--- @param input string The input string specifying the function
--- @param source CopilotChat.source The source containing buffer and window information
--- @return table The result table with documentation
local function resolve_lsp(init_func, input, source)
  -- Initialize and validate input
  if not input or input == "" then
    return {}
  end

  if init_func then
    init_func()
  end

  local bufnr = source.bufnr

  -- Parse input to get filename and function name
  local filename, func_name = parse_function_input(input)
  if not func_name then
    return {}
  end

  -- Find function location
  local func_location = find_function_location(func_name, bufnr, true)

  -- Update filename from func_location if not provided
  if not filename and func_location then
    filename = func_location.filename
  elseif not func_location then
    vim.notify("Function not found: " .. func_name, vim.log.levels.WARN)
    return {}
  end

  -- Check LSP availability
  local has_lsp, clients_or_error = check_lsp_availability(bufnr)
  if not has_lsp then
    return {
      {
        content = "No LSP clients attached to buffer: " .. (filename or "unknown"),
        filename = "function_error",
        filetype = "markdown",
      },
    }
  end

  -- Fetch function documentation
  local function_text = fetch_function_documentation(bufnr, func_location)
  vim.notify("Function documentation fetched successfully: " .. function_text, vim.log.levels.INFO)

  -- Create and return the result
  local filetype = vim.bo[bufnr].filetype
  return create_result(function_text, func_name, filetype)
end

M.check_lsp_availability = check_lsp_availability
M.find_function_location = find_function_location
M.parse_function_input = parse_function_input
M.fetch_function_documentation = fetch_function_documentation
M.create_result = create_result
M.input_lsp = input_lsp
M.resolve_lsp = resolve_lsp

return M
