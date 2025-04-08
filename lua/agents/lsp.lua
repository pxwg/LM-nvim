local M = {}
function M.lsp_resolve(utils, input, source)
  if not input or input == "" then
    return {}
  end

  utils.schedule_main()

  local bufnr = source.bufnr
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local func_name = input

  -- Get position of selected function
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local function_pos

  -- Find function position
  for line_num, line_text in ipairs(lines) do
    local name_pattern = func_name:gsub("([^%w])", "%%%1") -- Escape special characters
    if line_text:match("function%s+" .. name_pattern .. "%s*%(") then
      function_pos = {
        line = line_num - 1, -- 0-indexed
        character = line_text:find("function"),
      }
      break
    end
  end

  if not function_pos then
    return {
      {
        content = "Could not locate function position for: " .. func_name,
        filename = "function_analysis_error",
        -- filetype = "markdown",
      },
    }
  end

  -- Get documentation through multiple LSP requests
  local docs = {}
  local definitions = {}

  -- 1. First try signature help
  local signature_help = vim.lsp.buf_request_sync(bufnr, "textDocument/signatureHelp", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = function_pos,
  }, 1000)

  if signature_help then
    for _, client_response in pairs(signature_help) do
      if client_response and client_response.result and client_response.result.signatures then
        for _, sig in ipairs(client_response.result.signatures) do
          if sig.documentation then
            if type(sig.documentation) == "string" then
              table.insert(docs, sig.documentation)
            elseif type(sig.documentation) == "table" and sig.documentation.value then
              table.insert(docs, sig.documentation.value)
            end
          end
          if sig.label then
            table.insert(docs, "Signature: " .. sig.label)
          end
        end
      end
    end
  end

  -- 2. Then try hover
  local hover_result = vim.lsp.buf_request_sync(bufnr, "textDocument/hover", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = function_pos,
  }, 1000)

  if hover_result then
    for _, client_response in pairs(hover_result) do
      if client_response and client_response.result and client_response.result.contents then
        local contents = client_response.result.contents
        if type(contents) == "string" then
          table.insert(docs, contents)
        elseif contents.kind == "markdown" or contents.kind == "plaintext" then
          table.insert(docs, contents.value)
        elseif contents.value then
          table.insert(docs, contents.value)
        elseif type(contents) == "table" and #contents > 0 then
          if type(contents[1]) == "string" then
            table.insert(docs, table.concat(contents, "\n"))
          elseif contents[1].value then
            table.insert(docs, contents[1].value)
          end
        end
      end
    end
  end

  -- 3. Try to get definition
  local definition_result = vim.lsp.buf_request_sync(bufnr, "textDocument/definition", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = function_pos,
  }, 1000)

  if definition_result then
    for _, client_response in pairs(definition_result) do
      if client_response and client_response.result then
        local defs = client_response.result
        if type(defs) == "table" then
          if defs.uri then -- Single definition
            table.insert(definitions, {
              uri = defs.uri,
              range = defs.range,
              path = vim.uri_to_fname(defs.uri),
              line = defs.range.start.line + 1,
            })
          else -- Multiple definitions
            for _, def in ipairs(defs) do
              if def.uri then
                table.insert(definitions, {
                  uri = def.uri,
                  range = def.range,
                  path = vim.uri_to_fname(def.uri),
                  line = def.range.start.line + 1,
                })
              end
            end
          end
        end
      end
    end
  end

  -- 4. Extract comment documentation above function (if available)
  if #definitions > 0 then
    for _, def in ipairs(definitions) do
      local def_bufnr = vim.fn.bufnr(def.path)
      if def_bufnr == -1 and vim.fn.filereadable(def.path) == 1 then
        def_bufnr = vim.fn.bufadd(def.path)
        vim.fn.bufload(def_bufnr)
      end

      if def_bufnr ~= -1 then
        local def_lines = vim.api.nvim_buf_get_lines(def_bufnr, 0, -1, false)
        local comment_block = {}
        local line_idx = def.range.start.line - 1

        -- Look for comments above function definition
        while line_idx >= 0 do
          local line = def_lines[line_idx + 1] -- 1-indexed in def_lines
          if line:match("^%s*%-%-%-") then -- LuaDoc style
            table.insert(comment_block, 1, line:gsub("^%s*%-%-%-?%s?", ""))
            line_idx = line_idx - 1
          elseif line:match("^%s*%-%-") then -- Regular comment
            table.insert(comment_block, 1, line:gsub("^%s*%-%-%s?", ""))
            line_idx = line_idx - 1
          elseif line:match("^%s*$") then -- Empty line, might be between comment and function
            line_idx = line_idx - 1
          else
            break
          end
        end

        if #comment_block > 0 then
          table.insert(docs, "Documentation comments:\n" .. table.concat(comment_block, "\n"))
        end
      end
    end
  end

  -- Find function calls throughout the buffer
  local call_positions = {}

  for line_num, line_text in ipairs(lines) do
    local simple_name = func_name:match("([^.]+)$") or func_name -- Get last part after dot if any
    -- Find potential function calls (simple pattern matching)
    local start_pos = 1
    while true do
      local call_pattern = simple_name .. "%s*%("
      local call_start = line_text:find(call_pattern, start_pos)
      if not call_start then
        break
      end

      -- Avoid counting the function definition itself
      if line_num - 1 ~= function_pos.line then
        table.insert(call_positions, {
          line = line_num - 1, -- 0-indexed
          character = call_start - 1,
          text = line_text:sub(call_start, line_text:find(")", call_start) or call_start + 20),
        })
      end
      start_pos = call_start + 1
    end
  end

  -- Generate output content
  local content = "# Function Analysis: " .. func_name .. "\n\n"

  -- Location information
  content = content .. "## Function Definition\n\n"
  content = content .. "- File: " .. filename .. "\n"
  content = content .. "- Line: " .. (function_pos.line + 1) .. "\n\n"

  -- Documentation
  content = content .. "## Documentation\n\n"
  if #docs > 0 then
    content = content .. table.concat(docs, "\n\n---\n\n")
  else
    content = content .. "No documentation available\n"
  end

  -- Show definition locations
  if #definitions > 0 then
    content = content .. "\n## Definition Locations\n\n"
    for _, def in ipairs(definitions) do
      content = content .. string.format("- %s:%d\n", def.path, def.line)
    end
    content = content .. "\n"
  end

  -- Show call locations if any
  content = content .. "## Function Calls\n\n"
  if #call_positions > 0 then
    for _, pos in ipairs(call_positions) do
      content = content .. "- Line " .. (pos.line + 1) .. ": `" .. pos.text .. "`\n"
    end
  else
    content = content .. "No calls to this function found in the current file.\n"
  end

  return {
    {
      content = content,
      filename = "function_analysis_" .. func_name,
      filetype = "markdown",
      score = 1.0, -- High relevance
    },
  }
end

return M
