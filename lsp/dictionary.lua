local capabilities = vim.lsp.protocol.make_client_capabilities()

return {
  name = "dictionary",
  cmd = { vim.fn.expand("~/dictionary_lsp/target/release/dictionary_lsp") },
  autostart = true,
  single_file_support = true,
  capabilities = capabilities,
  on_attach = function(client, _)
    -- 只在第一次 attach 时同步初始状态，避免后续 buffer attach 重复触发
    if vim.g.dict_initialized then
      return
    end
    vim.g.dict_initialized = true
    -- 服务器 CMP 默认开启；若当前处于中文模式（rime 开）则关闭 dict CMP
    if vim.g.rime_enabled then
      vim.schedule(function()
        client:request(
          "workspace/executeCommand",
          { command = "dictionary.toggle-cmp" },
          function(_, result, ctx, _)
            if ctx.client_id == client.id then
              vim.g.dict_enabled = result
            end
          end
        )
      end)
    end
  end,
}
