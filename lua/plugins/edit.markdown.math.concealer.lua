local function is_copilot_chat_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  return vim.bo[bufnr].filetype == "copilot-chat" or name:match("copilot%-chat") ~= nil
end

local function is_supported_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end

  local filetype = vim.bo[bufnr].filetype
  return filetype == "markdown" or filetype == "copilot-chat" or is_copilot_chat_buffer(bufnr)
end

local function normalize_copilot_chat_filetype(bufnr)
  if is_copilot_chat_buffer(bufnr) and vim.bo[bufnr].filetype == "" then
    vim.bo[bufnr].filetype = "copilot-chat"
  end
end

local function set_conceal_for_buffer_windows(bufnr)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_option_value("conceallevel", 2, { win = winid })
      vim.api.nvim_set_option_value("concealcursor", "nci", { win = winid })
    end
  end
end

local schedule_enable

local function attach_copilot_chat_updates(bufnr)
  if not is_copilot_chat_buffer(bufnr) or vim.b[bufnr].markdown_math_concealer_update_attached then
    return
  end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, changed_buf)
      schedule_enable(changed_buf, 120)
    end,
    on_detach = function(_, detached_buf)
      if vim.api.nvim_buf_is_valid(detached_buf) then
        vim.b[detached_buf].markdown_math_concealer_update_attached = false
      end
    end,
  })
  vim.b[bufnr].markdown_math_concealer_update_attached = true
end

local function enable_buffer(bufnr, attempt)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  attempt = attempt or 1

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  normalize_copilot_chat_filetype(bufnr)

  if not is_supported_buffer(bufnr) then
    return
  end

  set_conceal_for_buffer_windows(bufnr)

  local ok, concealer = pcall(require, "markdown-math-concealer")
  if not ok then
    if attempt < 5 then
      vim.defer_fn(function()
        enable_buffer(bufnr, attempt + 1)
      end, 500)
    else
      vim.notify("markdown-math-concealer is not loaded", vim.log.levels.WARN)
    end
    return
  end

  if concealer.enable_buf(bufnr) then
    attach_copilot_chat_updates(bufnr)
  end
end

schedule_enable = function(bufnr, delay_ms)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.b[bufnr].markdown_math_concealer_pending then
    return
  end

  vim.b[bufnr].markdown_math_concealer_pending = true
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].markdown_math_concealer_pending = false
      enable_buffer(bufnr)
    end
  end, delay_ms or 80)
end

return {
  "pxwg/markdown-math-concealer.nvim",
  dir = "/Users/pxwg-dogggie/markdown-concealer",
  name = "markdown-math-concealer.nvim",
  main = "markdown-math-concealer",
  enabled = false,
  lazy = false,
  opts = {
    filetypes = { "markdown", "copilot-chat" },
    diagnostics = "silent",
    provider = "mathjax-node",
    conceal = {
      inline = true,
      block = true,
    },
  },
  config = function(_, opts)
    require("markdown-math-concealer").setup(opts)

    local group = vim.api.nvim_create_augroup("MarkdownMathConcealerConfig", { clear = true })
    vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWinEnter" }, {
      group = group,
      callback = function(event)
        schedule_enable(event.buf, 80)
      end,
    })

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      schedule_enable(bufnr, 80)
    end
  end,
}
