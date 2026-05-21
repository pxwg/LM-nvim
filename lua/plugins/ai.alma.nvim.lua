local function alma_keymap(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
end

local function submit_alma_chat()
  require("alma").submit()
end

local function close_alma_chat()
  require("alma.ui.window").close({})
end

local function is_alma_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  return vim.bo[bufnr].filetype == "alma" or vim.api.nvim_buf_get_name(bufnr):match("^alma://") ~= nil
end

local function attach_alma_formula_images(bufnr, attempt)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  attempt = attempt or 1
  if not is_alma_buffer(bufnr) then
    return
  end

  if vim.bo[bufnr].filetype == "" then
    vim.bo[bufnr].filetype = "alma"
  end

  local ok_main, image_concealer = pcall(require, "math-conceal.image")
  local ok_runtime, runtime = pcall(require, "math-conceal.image.machine.runtime")
  if not ok_main or not ok_runtime then
    if attempt < 5 then
      vim.defer_fn(function()
        attach_alma_formula_images(bufnr, attempt + 1)
      end, 500)
    else
      vim.notify("math-conceal.image is not loaded for Alma buffer", vim.log.levels.WARN)
    end
    return
  end

  image_concealer._enabled_buffers[bufnr] = true
  local ok_render, err = pcall(runtime.render_buf, bufnr)
  if not ok_render then
    vim.notify("Alma formula render failed: " .. tostring(err), vim.log.levels.WARN)
    return
  end

  for _, delay_ms in ipairs({ 800, 1800, 3200 }) do
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) and image_concealer._enabled_buffers[bufnr] == true then
        pcall(runtime.refresh_visible_overlays, bufnr, { force_reupload_blocks = true, margin = 8 })
      end
    end, delay_ms)
  end
end

local function schedule_alma_formula_attach(bufnr, delay_ms)
  if not is_alma_buffer(bufnr) or vim.b[bufnr].alma_formula_attach_pending then
    return
  end

  vim.b[bufnr].alma_formula_attach_pending = true
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].alma_formula_attach_pending = false
      attach_alma_formula_images(bufnr)
    end
  end, delay_ms or 700)
end

return {
  "pxwg/alma.nvim",
  dev = true,
  enabled = vim.g.alma_enabled or false,
  cmd = {
    "Alma",
    "AlmaHealth",
    "AlmaThreadOpen",
    "AlmaThreadRefresh",
    "AlmaSubmit",
    "AlmaStop",
    "AlmaThreads",
    "AlmaThreadsGlobal",
    "AlmaProjects",
    "AlmaModels",
    "AlmaTools",
    "AlmaSkills",
    "AlmaMCPServers",
    "AlmaBuffers",
    "AlmaEvents",
    "AlmaToolDetails",
    "AlmaAgentCrew",
    "AlmaToggleBlock",
    "AlmaQuickfix",
    "AlmaBlockQuickfix",
    "AlmaDiff",
    "AlmaAttachFormulaImages",
    "ZkAlmaWorkspaceRegister",
    "ZkAlmaBlackboardBind",
    "ZkAlmaBlackboardUnbind",
    "ZkAlmaBlackboardStatus",
    "ZkAlmaReviewApprove",
    "ZkAlmaReviewReject",
    "ZkAlmaReviewComment",
    "ZkAlmaReviewApplyApproved",
    "ZkAlmaReviewGate",
    "ZkAlmaReviewPicker",
    "ZkAlmaReviewList",
    "ZkAlmaReviewGoto",
    "ZkAlmaReviewNext",
    "ZkAlmaReviewPrev",
    "ZkAlmaReviewClear",
  },
  keys = {
    {
      "<leader>am",
      function()
        vim.cmd("AlmaThreads")
      end,
      desc = "Alma Thread",
    },
    {
      "<leader>aM",
      function()
        vim.cmd("AlmaThreadsGlobal")
      end,
      desc = "Alma Thread Global",
    },
    {
      "<C-c>",
      function()
        vim.cmd("Alma")
      end,
      desc = "Alma",
    },
  },
  config = function()
    require("alma").setup({
      model = "plugin:openai-codex-auth:openai-codex:gpt-5.5",
      reasoning_effort = "xhigh",
      window_layout = "sidebar",
    })
    require("util.alma_zk_blackboard").setup()

    -- vim.api.nvim_create_user_command("AlmaAttachFormulaImages", function(opts)
    --   local bufnr = tonumber(opts.args) or vim.api.nvim_get_current_buf()
    --   attach_alma_formula_images(bufnr)
    -- end, {
    --   nargs = "?",
    --   desc = "Render and attach formula images in the current Alma buffer",
    -- })

    local alma_formula_group = vim.api.nvim_create_augroup("AlmaFormulaImages", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "alma",
      group = alma_formula_group,
      callback = function(event)
        alma_keymap(event.buf, { "n", "i" }, "<C-S>", submit_alma_chat, "Alma Submit")
        alma_keymap(event.buf, { "n", "i" }, "<C-s>", submit_alma_chat, "Alma Submit")
        alma_keymap(event.buf, "n", "<CR>", submit_alma_chat, "Alma Submit")
        alma_keymap(event.buf, "n", "q", close_alma_chat, "Alma Close Chat")
        require("util.rime_ls").attach_rime_to_buffer(event.buf)
        -- schedule_alma_formula_attach(event.buf, 900)
      end,
    })

    -- vim.api.nvim_create_autocmd("BufWinEnter", {
    --   group = alma_formula_group,
    --   callback = function(event)
    --     if is_alma_buffer(event.buf) then
    --       schedule_alma_formula_attach(event.buf, 900)
    --     end
    --   end,
    -- })
  end,
}
