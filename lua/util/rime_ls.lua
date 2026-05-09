local M = {}

local function is_rime_ls_attached()
  local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  for _, client in ipairs(clients) do
    if client.name == "rime_ls" then
      return true
    end
  end
  return false
end

function M.check_rime_status()
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    if client.name == "rime_ls" then
      return true
    end
  end
  return false
end

local tex = require("util.latex")

local function rime_toggle_color()
  if M.check_rime_status() and rime_toggled then
    return { bg = "#74c7ec", fg = "#313244", gui = "bold" }
  elseif rime_ls_active then
    return tex.in_text() and { bg = "#f38ba8", fg = "#313244", gui = "bold" }
      or { bg = "#fab387", fg = "#313244", gui = "bold" }
  elseif not rime_toggled and not rime_ls_active then
    return tex.in_text() and { bg = "#74c7ec", fg = "#313244", gui = "bold" }
      or { bg = "#fab387", fg = "#313244", gui = "bold" }
  end
end

local function rime_toggle_word()
  if is_rime_ls_attached() then
    if M.check_rime_status() and _G.rime_toggled then
      return "cn"
    elseif _G.rime_ls_active and tex.in_latex() then
      return "math"
    elseif _G.rime_ls_active then
      return tex.in_text() and "error" or "math"
    elseif not _G.rime_toggled and not _G.rime_ls_active then
      return tex.in_text() and "en" or "math"
    end
  else
    return "en"
  end
end

local function change_cursor_color()
  if M.rime_toggle_word() == "cn" then
    vim.cmd("highlight Cursor guifg=#313244 guibg=#74c7ec")
  else
    vim.cmd("highlight Cursor guifg=NONE guibg=NONE")
  end
end

local function attach_client_to_buffer(bufnr, client_name)
  if #vim.lsp.get_clients({ bufnr = bufnr, name = client_name }) > 0 then
    return true
  end

  local client = vim.lsp.get_clients({ name = client_name })[1]
  local client_id = client and client.id

  if not client_id and vim.lsp.config and vim.lsp.config[client_name] then
    client_id = vim.lsp.start(vim.lsp.config[client_name], { bufnr = bufnr })
  end

  if client_id then
    return vim.lsp.buf_attach_client(bufnr, client_id)
  end

  vim.notify(client_name .. " client not found", vim.log.levels.ERROR)
  return false
end

function M.attach_rime_to_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  attach_client_to_buffer(bufnr, "rime_ls")
  attach_client_to_buffer(bufnr, "dictionary")
end

function M.start_rime_ls()
  local job_id = vim.fn.jobstart(vim.fn.expand("~/rime-ls/target/release/rime_ls") .. " --listen", {
    on_stdout = function() end,
    on_stderr = function() end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.api.nvim_err_writeln("rime_ls exited with code " .. code)
      end
    end,
  })

  -- Create an autocommand to stop the job when Neovim exits
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      vim.fn.jobstop(job_id)
    end,
  })
end

M.change_cursor_color = change_cursor_color

M.rime_toggle_color = rime_toggle_color

M.rime_toggle_word = rime_toggle_word

return M
