local alsp = require("agents.lsp")

local function input_lsp(callback, source)
  return alsp.input_lsp(callback, source)
end

local function resolve_lsp(init_func, input, source)
  return alsp.resolve_lsp(init_func, input, source)
end

-- print(vim.inspect(resolve_lsp(nil, "resolve_lsp", { bufnr = 0 })))

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
          input = function(callback, source)
            vim.ui.input({
              prompt = "Enter Neovim command> ",
            }, callback)
          end,
          resolve = function(input, source)
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
        function_doc = {
          description = "Gets precise function document with LSP. Format: [filepath:]function_name",
          input = function(callback, source)
            return input_lsp(callback, source)
          end,
          resolve = function(input, source)
            return resolve_lsp(utils.schedule_main(), input, source)
          end,
        },
      },

      auto_insert_mode = false, -- Automatically enter insert mode when opening window and on new prompt
      debug = false, -- Enable debugging
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
      model = "gemini-2.5-pro", -- Set gemini model as default
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
