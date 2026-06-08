local function codex_buffer_role(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local filetype = vim.bo[bufnr].filetype
  if filetype == "codex-input" or vim.b[bufnr].codex_role == "composer" or vim.b[bufnr].codex_composer == true then
    return "input"
  end
  if filetype == "codex-history" or vim.b[bufnr].codex_role == "history" then
    return "history"
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if filetype == "codex" or name:match("^codex://") ~= nil then
    return "history"
  end

  return nil
end

local function is_codex_buffer(bufnr)
  return codex_buffer_role(bufnr) ~= nil
end

local function codex_math_conceal_mode(bufnr)
  return codex_buffer_role(bufnr) == "input" and "edit" or "presentation"
end

local function attach_codex_math_conceal(bufnr)
  pcall(function()
    require("lazy").load({ plugins = { "math-conceal.nvim" } })
  end)

  local ok, math_conceal = pcall(require, "math-conceal")
  if not ok or math_conceal.setup_buffer == nil then
    return
  end

  local desired_mode = codex_math_conceal_mode(bufnr)
  if
    vim.b[bufnr].math_conceal_applied_buffer_mode == desired_mode
    and type(math_conceal.get_buffer_config) == "function"
  then
    local ok_config, config = pcall(math_conceal.get_buffer_config, bufnr)
    if ok_config and config and config.mode == desired_mode then
      return
    end
  end

  math_conceal.setup_buffer(bufnr, {
    mode = desired_mode,
  })
  vim.b[bufnr].math_conceal_applied_buffer_mode = desired_mode

  local ok_manager, manager = pcall(require, "math-conceal.image.formula.manager")
  if ok_manager then
    pcall(manager.sync_cursor_conceal, bufnr, { force = true })
  end
end

local function attached_lsp_clients(bufnr)
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    names[client.name] = true
  end
  return names
end

local function attach_codex_lsp_clients(bufnr)
  pcall(vim.lsp.enable, { "rime_ls", "dictionary" })

  local ok, rime = pcall(require, "util.rime_ls")
  if ok and rime.attach_rime_to_buffer then
    rime.attach_rime_to_buffer(bufnr)
  end

  local names = attached_lsp_clients(bufnr)
  if names.rime_ls and names.dictionary then
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    if not names.rime_ls then
      pcall(vim.cmd, "LspStart rime_ls")
    end
    if not names.dictionary then
      pcall(vim.cmd, "LspStart dictionary")
    end
  end)

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) and ok and rime.attach_rime_to_buffer then
      rime.attach_rime_to_buffer(bufnr)
    end
  end, 250)
end

local function attach_codex_input_helpers(bufnr)
  local role = codex_buffer_role(bufnr)
  if role == nil then
    return
  end

  if role == "input" then
    attach_codex_lsp_clients(bufnr)
  end
  attach_codex_math_conceal(bufnr)
end

local function attach_all_codex_input_helpers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if is_codex_buffer(bufnr) then
      attach_codex_input_helpers(bufnr)
    end
  end
end

local function schedule_codex_input_helpers(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  vim.schedule(function()
    attach_codex_input_helpers(bufnr)
  end)

  for _, delay in ipairs({ 120, 600, 1400 }) do
    vim.defer_fn(function()
      attach_codex_input_helpers(bufnr)
    end, delay)
  end
end

local function schedule_all_codex_input_helpers()
  vim.schedule(attach_all_codex_input_helpers)
  for _, delay in ipairs({ 120, 600, 1400, 2600 }) do
    vim.defer_fn(attach_all_codex_input_helpers, delay)
  end
end

local function run_codex_command(command)
  vim.cmd(command)
  schedule_all_codex_input_helpers()
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
        run_codex_command("Codex pick")
      end,
      desc = "Codex Threads",
    },
    {
      "<leader>aC",
      function()
        run_codex_command("Codex new")
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
      buffer = {
        on_attach = function(bufnr)
          schedule_codex_input_helpers(bufnr)
        end,
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "codex", "codex-history", "codex-input" },
      group = vim.api.nvim_create_augroup("CodexNvimConfig", { clear = true }),
      callback = function(event)
        if vim.bo[event.buf].filetype == "codex" then
          vim.keymap.set({ "n", "i" }, "<C-s>", function()
            require("codex").submit()
          end, { buffer = event.buf, silent = true, desc = "Codex Submit" })
          vim.keymap.set("n", "<CR>", function()
            require("codex").submit()
          end, { buffer = event.buf, silent = true, desc = "Codex Submit" })
          vim.keymap.set("n", "q", function()
            vim.api.nvim_win_close(0, true)
          end, { buffer = event.buf, silent = true, desc = "Codex Close Chat" })
        end

        schedule_codex_input_helpers(event.buf)
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "CodexBufferOpened",
      group = vim.api.nvim_create_augroup("CodexNvimBufferOpened", { clear = true }),
      callback = function(event)
        local data = event.data or {}
        schedule_codex_input_helpers(data.bufnr or event.buf)
      end,
    })

    vim.api.nvim_create_user_command("CodexAttachInputHelpers", function(opts)
      local bufnr = tonumber(opts.args)
      if bufnr then
        schedule_codex_input_helpers(bufnr)
      else
        schedule_all_codex_input_helpers()
      end
    end, {
      nargs = "?",
      desc = "Attach rime/dictionary and math conceal helpers to Codex buffers",
    })

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if is_codex_buffer(bufnr) then
        schedule_codex_input_helpers(bufnr)
      end
    end
  end,
}
