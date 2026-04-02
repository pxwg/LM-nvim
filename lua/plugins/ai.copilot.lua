return {
  "zbirenbaum/copilot.lua",
  enabled = function()
    return not require("util.vscode").is_vscode()
  end,
  cmd = "Copilot",
  build = ":Copilot auth",
  event = "InsertEnter",
  init = function()
    local group = vim.api.nvim_create_augroup("user.copilot_cleanup", { clear = true })

    local function cleanup_copilot_server()
      if package.loaded["copilot.command"] then
        pcall(function()
          require("copilot.command").disable()
        end)
      end

      local children = vim.api.nvim_get_proc_children(vim.fn.getpid()) or {}
      for _, pid in ipairs(children) do
        local proc = vim.api.nvim_get_proc(pid)
        if proc and proc.name == "node" then
          local result = vim.system({ "ps", "-o", "command=", "-p", tostring(pid) }, { text = true }):wait()
          local cmdline = result.stdout or ""
          if cmdline:find("/copilot/js/language%-server%.js", 1, false) then
            pcall(vim.uv.kill, pid, 15)
          end
        end
      end
    end

    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = group,
      callback = cleanup_copilot_server,
      desc = "Stop copilot.lua and reap its language server on exit",
    })
  end,
  opts = {
    suggestion = {
      enabled = not vim.g.ai_cmp,
      auto_trigger = true,
      keymap = {
        accept = "<Tab>", -- handled by nvim-cmp / blink.cmp
        next = "<M-]>",
        prev = "<M-[>",
      },
    },
    panel = { enabled = false },
    filetypes = {
      markdown = true,
      help = true,
    },
  },
}
