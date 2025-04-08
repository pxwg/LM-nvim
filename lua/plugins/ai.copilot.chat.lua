local USER_SYSTEM_PROMPT = [[When asked for your name, you must respond with "GitHub Copilot".
Follow the user's requirements carefully & to the letter.
Keep your answers short and impersonal.
The user works in an IDE called Neovim which has a concept for editors with open files, integrated unit test support, an output pane that shows the output of running the code as well as an integrated terminal.
The user is working on a darwin (MacOS) machine. Please respond with system specific commands if applicable.
You will receive code snippets that include line number prefixes - use these to maintain correct position references but remove them when generating output.

When presenting code changes:

1. For each change, first provide a header outside code blocks with format:
   [file:<file_name>](<file_path>) line:<start_line>-<end_line>

2. Then wrap the actual code in triple backticks with the appropriate language identifier.

3. Keep changes minimal and focused to produce short diffs.

4. Include complete replacement code for the specified line range with:
   - Proper indentation matching the source
   - All necessary lines (no eliding with comments)
   - No line number prefixes in the code

5. Address any diagnostics issues when fixing code.

When you need additional context, request it using this format:

> #<command>:`<input>`

struc Command:
file, files, filenames,buffer, buffers, git, system, nvim

Examples:
> #file:`path/to/file.js`        (loads specific file)
> #buffers:`visible`             (loads all visible buffers)
> #git:`staged`                  (loads git staged changes)
> #system:`uname -a`             (loads system information)
> #nvim:`echo "Hello"`           (executes command in nvim and returns output)

Guidelines:
- Always request context when needed rather than guessing about files or code
- Use the > format on a new line when requesting context
- Output context commands directly - never ask if the user wants to provide information
- Assume the user will provide requested context in their next response
- Always try to provide a complete solution
- Don't avoid to ask for context if you need it, even you need to ask for it multiple times and run multiple commands (both system commands and neovim commands). All the commands would be run savely.

Abilities:
- You can generate code snippets, refactor code, and provide explanations from the context the USER provides.
- USER would ask you to write whole files, functions, or classes without USER's help, 
  but you can also ask USER to provide context if you need it. 
- In order to generate bugfree, working, production-ready, optimized, clean, robust, and maintainable code, you need to run system commands and Neovim commands to gather context and refactor your code.
- Neovim commands include: basic vim commands, LSP (diagnostics, definition and completion are included), DAP.

Example:
- User: "Can you write a function to calculate the factorial of a number?"
- You: <write the first version> --> need to test --> request to run system command/neovim command to test it
---------------command output---------------
- User: <comamnd outputs>
if (get the error) --> ask to get diagnostics/run unit test/get DAP test etc.
if (not get the error) --> generate the test cases and run the test case.

Norm:
- You:
  > Current file: `path/to/file.lua`
  > Code You Wrote
  [file:<file_name>](<file_path>) line:<start_line>-<end_line>
  ```lua
  function factorial(n)
    if n == 0 then
      return 1
    else
      return n * factorial(n - 1)
    end
  end
  ```
  > Request to run the results/test/debug/diagnostics
  > #nvim:lua require('dap').continue()
  > #nvim: %lua
  
- Command Output
- User: ^Output: 
        <command outputs1>;
        <command outputs2>; ...

(The process above would be repeated until the code is correct and working)
#End of this Example

Available context providers and their usage:

]]

return {
  "CopilotC-Nvim/CopilotChat.nvim",
  branch = "main",
  dependencies = {
    { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
    { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
  },
  build = "make tiktoken", -- Only on MacOS or Linux

  keys = {
    {
      "<leader>aa",
      function()
        vim.cmd("CopilotChatToggle")
        vim.cmd("LspStart rime_ls")
        -- vim.cmd(":vert wincmd L")
      end,
      desc = "CopilotChat",
    },
    {
      "<C-c>",
      function()
        vim.cmd("CopilotChatToggle")
        vim.cmd("LspStart rime_ls")
        -- vim.cmd(":vert wincmd L")
      end,
      desc = "CopilotChat",
    },
  },

  opts = function()
    local utils = require("CopilotChat.utils")
    return {
      contexts = {
        neovim = {
          description = "Executes Neovim command and returns the output. Format: <command>",
          input = function(callback, _source) -- Added underscore to mark unused param
            vim.ui.input({
              prompt = "Enter Neovim command> ",
            }, callback)
          end,
          resolve = function(input, _source) -- Added underscore to mark unused param
            if not input or input == "" then
              return {}
            end

            utils.schedule_main()

            -- Use execute() to capture output instead of redir
            local output = ""
            local success, result = pcall(function()
              return vim.api.nvim_exec2(input, { output = true })
            end)

            if success then
              output = result.output
            else
              output = "Error executing command: " .. tostring(result)
            end

            -- If output is empty, try to provide some feedback
            if output == "" then
              if success then
                output = "Command executed successfully with no output."
              else
                output = "Command failed with no output."
              end
            end
            return {
              {
                content = "Command: " .. input .. "\n\n" .. output,
                filename = "neovim_command_output",
                filetype = "text",
                score = 1.0, -- High relevance
              },
            }
          end,
        },
        function_def = {
          description = "Gets precise function definition using LSP. Format: [filename:]function_name",
          input = function(callback, source)
            local bufnr = source.bufnr
            local filename = vim.api.nvim_buf_get_name(bufnr)

            -- Check if LSP is available for this buffer
            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            if #clients == 0 then
              vim.notify("No LSP clients attached to buffer", vim.log.levels.WARN)
              vim.ui.input({
                prompt = "Enter [filename:]function_name> ",
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

                -- Find all symbols that represent function calls
                local function_calls = {}
                local seen = {}

                -- Recursive function to traverse symbol tree
                local function collect_functions(items)
                  if not items or vim.tbl_isempty(items) then
                    return
                  end

                  for _, item in ipairs(items) do
                    -- Function (12) or Method (6) kinds
                    if item.kind == 12 or item.kind == 6 then
                      local name = item.name
                      if not seen[name] then
                        seen[name] = true
                        table.insert(function_calls, {
                          name = name,
                          kind = item.kind == 12 and "Function" or "Method",
                        })
                      end
                    end

                    -- Check children for nested functions
                    if item.children then
                      collect_functions(item.children)
                    end
                  end
                end

                -- Process all symbols
                collect_functions(result)

                -- If no function calls found, allow manual input
                if #function_calls == 0 then
                  vim.notify("No functions found in document", vim.log.levels.INFO)
                  vim.ui.input({
                    prompt = "Enter [filename:]function_name> ",
                  }, callback)
                  return
                end

                -- Sort function calls alphabetically
                table.sort(function_calls, function(a, b)
                  return a.name < b.name
                end)

                -- Display function call selector
                vim.ui.select(function_calls, {
                  prompt = "Select function:",
                  format_item = function(item)
                    return string.format("%s (%s)", item.name, item.kind)
                  end,
                }, function(choice)
                  if not choice then
                    callback("")
                    return
                  end

                  if vim.fn.filereadable(filename) == 1 then
                    callback(choice.name)
                  else
                    callback(filename .. ":" .. choice.name)
                  end
                end)
              end
            )
          end,
          resolve = function(input, source)
            if not input or input == "" then
              return {}
            end

            utils.schedule_main()

            local filename, func_name
            if input:find(":") then
              filename, func_name = input:match("([^:]+):(.+)")
            else
              filename = vim.api.nvim_buf_get_name(source.bufnr)
              func_name = input
            end

            -- Get or open buffer for the file
            local bufnr
            if vim.fn.filereadable(filename) == 1 then
              bufnr = vim.fn.bufnr(filename)
              if bufnr == -1 then
                bufnr = vim.fn.bufadd(filename)
                vim.fn.bufload(bufnr)
              end
            else
              return {
                {
                  content = "File not found: " .. filename,
                  filename = "function_error",
                  filetype = "text",
                },
              }
            end

            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            if #clients == 0 then
              return {
                {
                  content = "No LSP clients attached to buffer: " .. filename,
                  filename = "function_error",
                  filetype = "markdown",
                },
              }
            end

            -- Request document symbols from LSP
            local symbols = vim.lsp.buf_request_sync(
              bufnr,
              "textDocument/documentSymbol",
              { textDocument = vim.lsp.util.make_text_document_params(bufnr) },
              1000
            )
            -- Process symbols to find our function
            local function_range = nil

            -- Helper function to recursively search for function in symbols
            local function find_function(items)
              if not items or vim.tbl_isempty(items) then
                return nil
              end

              for _, item in ipairs(items) do
                if (item.kind == 12 or item.kind == 9) and item.name == func_name then -- Function or Method
                  return item.range or (item.location and item.location.range)
                end

                -- Check for children/nested symbols
                if item.children then
                  local range = find_function(item.children)
                  if range then
                    return range
                  end
                end
              end
              return nil
            end

            if not symbols then
              return {
                {
                  content = "No response from LSP for " .. filename,
                  filename = "function_error",
                  filetype = "text",
                },
              }
            end

            for _, client_response in pairs(symbols or {}) do
              if client_response and client_response.result then
                function_range = find_function(client_response.result)
                if function_range then
                  break
                end
              end
            end

            if not function_range then
              return {
                {
                  content = "Function '" .. func_name .. "' not found in " .. filename,
                  filename = "function_not_found",
                  filetype = "text",
                },
              }
            end

            -- Extract function text from buffer
            local start_line = function_range.start.line
            local end_line = function_range["end"].line + 1
            local function_text = ""

            -- Try to get function documentation using LSP hover
            local hover_params = {
              textDocument = vim.lsp.util.make_text_document_params(bufnr),
              position = { line = start_line, character = 0 },
            }

            local hover_result = vim.lsp.buf_request_sync(bufnr, "textDocument/hover", hover_params, 1000)
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
                    break
                  end
                end
              end
            end

            -- Append function implementation
            function_text = function_text
              .. table.concat(vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false), "\n")

            local filetype = vim.bo[bufnr].filetype
            print(function_text)
            return {
              {
                content = function_text,
                filename = "function_" .. func_name,
                filetype = filetype,
                score = 1.0, -- High relevance
              },
            }
          end,
        },
      },

      auto_insert_mode = false, -- Automatically enter insert mode when opening window and on new prompt
      debug = true, -- Enable debugging
      reset = {
        normal = "<C-b>",
        insert = "<C-b>",
      },
      prompts = {
        nvim_runner = {
          system_prompt = USER_SYSTEM_PROMPT,
        },
      },
      complete = {
        detail = "Use @<localleader>s or /<localleader>s for options.",
        insert = "<localleader>s",
      },
      question_header = "󰩃  Doggie  ",
      answer_header = "⚡ Copilot ",
      model = "claude-3.7-sonnet-thought", -- Set Claude model as default
      window = {
        layout = "vertical", -- 'vertical', 'horizontal', 'float', 'replace'
        width = 0.3, -- fractional width of parent, or absolute width in columns when > 1
      },
    }
  end,
  cmd = "CopilotChat",
  config = function(_, opts)
    local chat = require("CopilotChat")

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "copilot-chat",
      callback = function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
        -- vim.cmd("LspStart rime_ls")
      end,
    })

    chat.setup(opts)
  end,
}
