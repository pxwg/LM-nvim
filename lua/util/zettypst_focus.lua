-- Only select the current note. Typst owns title/stub discovery and dependencies.
local M = {}

function M.note(path)
  if not path or path == '' then return end
  local root = vim.fs.root(path, '.zettypst')
  if not root or not vim.uv.fs_stat(root .. '/.zettypst/focus.typ') then return end
  local relative = path:sub(#root + 2)
  if not vim.startswith(path, root .. '/') or not relative:match('^note/[^/]+%.typ$') then return end
  return root, vim.fn.fnamemodify(path, ':t:r')
end

function M.args(root, id)
  return { '--root', root, '--input=focus=' .. id }
end

function M.select(client, buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_get_current_buf() ~= buf then return false end
  local root, id = M.note(vim.api.nvim_buf_get_name(buf))
  if not root or client.root_dir ~= root then return false end
  if client._zettyp_focus == id then return true end
  client._zettyp_focus = id
  local settings = client.settings
  settings.projectResolution = 'singleFile'
  settings.rootPath = root
  settings.typstExtraArgs = M.args(root, id)
  client:notify('workspace/didChangeConfiguration', { settings = settings })
  client:request('workspace/executeCommand', {
    command = 'tinymist.pinMain', arguments = { root .. '/focus.typ' },
  }, function(err)
    if err then
      client._zettyp_focus = nil
      vim.schedule(function() vim.notify('Tinymist focus: ' .. err.message, vim.log.levels.WARN) end)
    end
  end, buf)
  return true
end

function M.setup()
  local group = vim.api.nvim_create_augroup('ZetTypstLocalFocus', { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', { group = group, pattern = '*.typ', callback = function(e)
    vim.schedule(function()
      for _, client in ipairs(vim.lsp.get_clients({ name = 'tinymist', bufnr = e.buf })) do
        M.select(client, e.buf)
      end
    end)
  end })
  -- Remove the retired command when this module is explicitly reloaded.
  pcall(vim.api.nvim_del_user_command, 'ZetFocusIndex')
  require('util.zettypst_titles').setup()
end

return M
