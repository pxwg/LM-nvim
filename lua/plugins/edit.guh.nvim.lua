return {
  "justinmk/guh.nvim",
  cmd = "Guh",
  config = function()
    local function is_guh_buffer(bufnr)
      return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr):match("^guh://") ~= nil
    end

    local function attach_client_to_buffer(bufnr, client_name)
      if #vim.lsp.get_clients({ bufnr = bufnr, name = client_name }) > 0 then
        return true
      end

      pcall(vim.lsp.enable, { client_name })

      local client = vim.lsp.get_clients({ name = client_name })[1]
      local client_id = client and client.id

      if not client_id and vim.lsp.config and vim.lsp.config[client_name] then
        client_id = vim.lsp.start(vim.lsp.config[client_name], { bufnr = bufnr })
      end

      if client_id then
        return vim.lsp.buf_attach_client(bufnr, client_id)
      end

      return false
    end

    local function attach_guh_lsp(bufnr)
      if not is_guh_buffer(bufnr) then
        return
      end

      if vim.bo[bufnr].buftype == "acwrite" then
        require("util.rime_ls").attach_rime_to_buffer(bufnr)
      else
        attach_client_to_buffer(bufnr, "dictionary")
      end
    end

    local function schedule_guh_lsp_attach(bufnr)
      bufnr = bufnr or vim.api.nvim_get_current_buf()

      vim.schedule(function()
        attach_guh_lsp(bufnr)
      end)

      for _, delay in ipairs({ 120, 600, 1400 }) do
        vim.defer_fn(function()
          attach_guh_lsp(bufnr)
        end, delay)
      end
    end

    local group = vim.api.nvim_create_augroup("GuhLspAttach", { clear = true })

    vim.api.nvim_create_autocmd({ "BufWinEnter", "BufFilePost", "TermClose", "FileType" }, {
      group = group,
      callback = function(event)
        schedule_guh_lsp_attach(event.buf)
      end,
    })

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      schedule_guh_lsp_attach(bufnr)
    end
  end,
}
