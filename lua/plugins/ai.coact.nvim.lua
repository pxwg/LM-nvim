local function coact_buffer_role(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local filetype = vim.bo[bufnr].filetype
  if filetype == "coact-input" or vim.b[bufnr].coact_role == "composer" or vim.b[bufnr].coact_composer == true then
    return "input"
  end
  if filetype == "coact-history" or vim.b[bufnr].coact_role == "history" then
    return "history"
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if filetype == "coact" or name:match("^coact://") ~= nil then
    return "history"
  end

  return nil
end

local function is_coact_buffer(bufnr)
  return coact_buffer_role(bufnr) ~= nil
end

local function coact_math_conceal_mode(bufnr)
  return coact_buffer_role(bufnr) == "input" and "edit" or "presentation"
end

local function attach_coact_math_conceal(bufnr)
  pcall(function()
    require("lazy").load({ plugins = { "math-conceal.nvim" } })
  end)

  local ok, math_conceal = pcall(require, "math-conceal")
  if not ok or math_conceal.setup_buffer == nil then
    return
  end

  local desired_mode = coact_math_conceal_mode(bufnr)
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

local function attach_coact_lsp_clients(bufnr)
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

local function attach_coact_input_helpers(bufnr)
  local role = coact_buffer_role(bufnr)
  if role == nil then
    return
  end

  if role == "input" then
    attach_coact_lsp_clients(bufnr)
  end
  attach_coact_math_conceal(bufnr)
end

local function attach_all_coact_input_helpers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if is_coact_buffer(bufnr) then
      attach_coact_input_helpers(bufnr)
    end
  end
end

local function schedule_coact_input_helpers(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  vim.schedule(function()
    attach_coact_input_helpers(bufnr)
  end)

  for _, delay in ipairs({ 120, 600, 1400 }) do
    vim.defer_fn(function()
      attach_coact_input_helpers(bufnr)
    end, delay)
  end
end

local function schedule_all_coact_input_helpers()
  vim.schedule(attach_all_coact_input_helpers)
  for _, delay in ipairs({ 120, 600, 1400, 2600 }) do
    vim.defer_fn(attach_all_coact_input_helpers, delay)
  end
end

local function run_coact_command(command)
  vim.cmd(command)
  schedule_all_coact_input_helpers()
end

return {
  "pxwg/coact.nvim",
  dir = "/Users/pxwg-dogggie/codex.nvim",
  enabled = vim.g.coact_nvim_enabled ~= false,
  cmd = {
    "Coact",
  },
  keys = {
    {
      "<leader>ac",
      function()
        run_coact_command("Coact pick")
      end,
      desc = "Coact Threads",
    },
    {
      "<leader>aC",
      function()
        run_coact_command("Coact new")
      end,
      desc = "Coact New Thread",
    },
    {
      "<leader>ai",
      function()
        run_coact_command("Coact completion-inline")
      end,
      desc = "Coact Inline Completion",
    },
    {
      "<leader>an",
      function()
        run_coact_command("Coact completion-nes")
      end,
      desc = "Coact Next Edit",
    },
    {
      "<leader>aN",
      function()
        run_coact_command("Coact completion-nes-accept")
      end,
      desc = "Coact Accept Next Edit",
    },
    {
      "<leader>aj",
      function()
        run_coact_command("Coact completion-nes-jump")
      end,
      desc = "Coact Jump Next Edit",
    },
    {
      "<leader>ak",
      function()
        run_coact_command("Coact completion-nes-dismiss")
      end,
      desc = "Coact Dismiss Next Edit",
    },
    {
      "<leader>al",
      function()
        run_coact_command("Coact completion-log")
      end,
      desc = "Coact Completion Log",
    },
  },
  config = function()
    require("coact").setup({
      provider = "pi",
      thread = {
        approval_policy = "on-request",
        approvals_reviewer = "user",
        sandbox = "workspace-write",
      },
      ui = {
        layout = "sidebar",
      },
      suggestions = {
        enabled = true,
        model = "gpt-5.3-codex-spark",
        inline = {
          enabled = true,
          debounce_ms = 900,
        },
        nes = {
          enabled = true,
          debounce_ms = 700,
        },
      },
      buffer = {
        on_attach = function(bufnr)
          schedule_coact_input_helpers(bufnr)
        end,
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "coact", "coact-history", "coact-input" },
      group = vim.api.nvim_create_augroup("CoactNvimConfig", { clear = true }),
      callback = function(event)
        if vim.bo[event.buf].filetype == "coact" then
          vim.keymap.set({ "n", "i" }, "<C-s>", function()
            require("coact").submit()
          end, { buffer = event.buf, silent = true, desc = "Coact Submit" })
          vim.keymap.set("n", "<CR>", function()
            require("coact").submit()
          end, { buffer = event.buf, silent = true, desc = "Coact Submit" })
          vim.keymap.set("n", "q", function()
            vim.api.nvim_win_close(0, true)
          end, { buffer = event.buf, silent = true, desc = "Coact Close Chat" })
        end

        schedule_coact_input_helpers(event.buf)
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "CoactBufferOpened",
      group = vim.api.nvim_create_augroup("CoactNvimBufferOpened", { clear = true }),
      callback = function(event)
        local data = event.data or {}
        schedule_coact_input_helpers(data.bufnr or event.buf)
      end,
    })

    vim.api.nvim_create_user_command("CoactAttachInputHelpers", function(opts)
      local bufnr = tonumber(opts.args)
      if bufnr then
        schedule_coact_input_helpers(bufnr)
      else
        schedule_all_coact_input_helpers()
      end
    end, {
      nargs = "?",
      desc = "Attach rime/dictionary and math conceal helpers to Coact buffers",
    })

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if is_coact_buffer(bufnr) then
        schedule_coact_input_helpers(bufnr)
      end
    end
  end,
}
