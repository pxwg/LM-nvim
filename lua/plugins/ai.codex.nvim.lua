local function attach_codex_math_conceal(bufnr)
  local ok, math_conceal = pcall(require, "math-conceal")
  if not ok or math_conceal.setup_buffer == nil then
    return
  end

  math_conceal.setup_buffer(bufnr, {
    mode = "preview",
  })

  local ok_image, image = pcall(require, "math-conceal.image")
  if ok_image and image.config ~= nil then
    image.config.conceal_in_normal = true
  end

  local ok_manager, manager = pcall(require, "math-conceal.image.formula.manager")
  if ok_manager then
    pcall(manager.sync_cursor_conceal, bufnr, { force = true })
  end
end

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

        attach_codex_math_conceal(event.buf)
      end,
    })
  end,
}
