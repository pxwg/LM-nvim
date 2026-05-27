local function is_codex_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  return vim.bo[bufnr].filetype == "codex" or name:match("^codex://") ~= nil
end

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

local function attach_codex_input_helpers(bufnr)
  if not is_codex_buffer(bufnr) then
    return
  end

  local ok, rime = pcall(require, "util.rime_ls")
  if ok and rime.attach_rime_to_buffer then
    rime.attach_rime_to_buffer(bufnr)
  end

  attach_codex_math_conceal(bufnr)
end

local function schedule_codex_input_helpers(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  vim.schedule(function()
    attach_codex_input_helpers(bufnr)
  end)

  for _, delay in ipairs({ 120, 600 }) do
    vim.defer_fn(function()
      attach_codex_input_helpers(bufnr)
    end, delay)
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

        schedule_codex_input_helpers(event.buf)
      end,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      group = vim.api.nvim_create_augroup("CodexNvimAttach", { clear = true }),
      callback = function(event)
        if is_codex_buffer(event.buf) then
          schedule_codex_input_helpers(event.buf)
        end
      end,
    })

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if is_codex_buffer(bufnr) then
        schedule_codex_input_helpers(bufnr)
      end
    end
  end,
}
