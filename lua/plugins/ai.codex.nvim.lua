return {
  "pxwg/codex.nvim",
  dir = "/Users/pxwg-dogggie/codex.nvim",
  enabled = vim.g.codex_nvim_enabled ~= false,
  cmd = {
    "Codex",
  },
  keys = {
    {
      "<leader>ac",
      function()
        vim.cmd("Codex pick")
      end,
      desc = "Codex Threads",
    },
    {
      "<leader>aC",
      function()
        vim.cmd("Codex new")
      end,
      desc = "Codex New Thread",
    },
  },
  config = function()
    require("codex").setup({
      thread = {
        approval_policy = "on-request",
        approvals_reviewer = "user",
        sandbox = "workspace-write",
      },
      ui = {
        layout = "sidebar",
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "codex",
      group = vim.api.nvim_create_augroup("CodexNvimConfig", { clear = true }),
      callback = function(event)
        vim.keymap.set({ "n", "i" }, "<C-s>", function()
          require("codex").submit()
        end, { buffer = event.buf, silent = true, desc = "Codex Submit" })
        vim.keymap.set("n", "<CR>", function()
          require("codex").submit()
        end, { buffer = event.buf, silent = true, desc = "Codex Submit" })
        vim.keymap.set("n", "q", function()
          vim.api.nvim_win_close(0, true)
        end, { buffer = event.buf, silent = true, desc = "Codex Close Chat" })

        local ok, rime = pcall(require, "util.rime_ls")
        if ok and rime.attach_rime_to_buffer then
          rime.attach_rime_to_buffer(event.buf)
        end
      end,
    })
  end,
}
