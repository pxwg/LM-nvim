local focus = require('util.zettypst_focus')
focus.setup()

return {
  name = 'tinymist',
  root_markers = { '.zettypst', 'tinymist.lock', '.git', 'typst.toml' },
  cmd = { 'tinymist' },
  filetypes = { 'typst' },
  capabilities = vim.lsp.protocol.make_client_capabilities(),
  settings = { projectResolution = 'lockDatabase', invertColors = 'auto', exportPdf = 'never' },
  before_init = function(params, config)
    if config.root_dir and vim.uv.fs_stat(config.root_dir .. '/.zettypst/source.toml') then
      -- Mutate the settings table captured by Neovim before this callback.
      config.settings.projectResolution = 'singleFile'
      config.settings.rootPath = config.root_dir
      local root, id = focus.note(vim.api.nvim_buf_get_name(0))
      config.settings.typstExtraArgs = root == config.root_dir and focus.args(root, id)
        or { '--root', config.root_dir }
      params.initializationOptions = vim.deepcopy(config.settings)
    end
  end,
  on_attach = function(client, bufnr)
    -- FileType/on_attach may run inside a temporary buffer context. Select only
    -- after that context unwinds, so loading a target cannot steal focus.
    if client.root_dir and vim.uv.fs_stat(client.root_dir .. '/.zettypst/focus.typ') then
      vim.schedule(function() focus.select(client, bufnr) end)
      return
    end
    local main = client.root_dir and (client.root_dir .. '/index.typ')
    if not main or vim.fn.filereadable(main) == 0 then main = vim.api.nvim_buf_get_name(bufnr) end
    client:request('workspace/executeCommand', {
      command = 'tinymist.pinMain', arguments = { main },
    }, function(err)
      if err then vim.schedule(function()
        vim.notify('Tinymist pinMain: ' .. vim.inspect(err), vim.log.levels.WARN)
      end) end
    end, bufnr)
  end,
}
