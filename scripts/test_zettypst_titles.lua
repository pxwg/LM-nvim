-- Run from the Neovim config root:
-- nvim --headless -u NONE -l scripts/test_zettypst_titles.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/site')
local root = vim.fn.tempname()
vim.fn.mkdir(root .. '/.zettypst', 'p')
vim.fn.mkdir(root .. '/note', 'p')
root = vim.uv.fs_realpath(root)
vim.fn.writefile({}, root .. '/.zettypst/focus.typ')
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(buf, root .. '/note/a.typ')
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  '= Current <a>', '@b @b @section', '```typst', '@b', '```', '// @b',
})
vim.wo.conceallevel = 2
vim.wo.concealcursor = 'nc'
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local requests = {}
local client = { root_dir = root, _zettyp_focus = 'a', name = 'tinymist', attached_buffers = { [buf] = true } }
function client:request(method, params, callback)
  assert(method == 'workspace/executeCommand')
  assert(params.command == 'tinymist.exportQuery')
  assert(params.arguments[3].write == false)
  requests[#requests + 1] = callback
  return true, #requests
end
function client:cancel_request(_) end
local get_clients = vim.lsp.get_clients
vim.lsp.get_clients = function() return { client } end
local titles = require('util.zettypst_titles')
local function await_request(n)
  assert(vim.wait(2000, function() return #requests >= n end, 10), titles.status)
end
local function reply(n, focus, title)
  requests[n](nil, { data = vim.base64.encode(vim.json.encode({
    version = 1, focus = focus or 'a', titles = { { id = 'b', title = title or '中文 title' } },
  })) })
end
local function marks(win)
  local ns = vim.api.nvim_get_namespaces()['zettypst_titles_' .. (win or vim.api.nvim_get_current_win())]
  return ns and vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true }) or {}
end
local function move(row, col)
  vim.api.nvim_win_set_cursor(0, { row, col })
  vim.api.nvim_exec_autocmds('CursorMoved', {})
end
local ok, err = pcall(function()
  titles.setup()
  await_request(1); reply(1)
  assert(titles.status == 'ready')
  assert(#marks() == 4, 'only two actual references should be decorated')
  move(2, 0)
  assert(#marks() == 2, 'cursor must reveal only its reference')
  move(1, 0)
  vim.wo.conceallevel = 0
  vim.api.nvim_exec_autocmds('OptionSet', { pattern = 'conceallevel' })
  assert(#marks() == 0, 'no virtual title when conceal is disabled')
  vim.wo.conceallevel = 2
  titles.refresh(); await_request(2)
  titles.refresh(); await_request(3)
  reply(2, 'a', 'stale')
  assert(titles.status == 'pending' and #marks() == 0, 'cancelled response must not render')
  reply(3, 'b')
  assert(titles.status == 'unavailable' and #marks() == 0, 'wrong focus must not render')
  titles.refresh(); await_request(4)
  requests[4]({ message = 'compile failure' })
  assert(titles.status == 'unavailable' and #marks() == 0)
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { '= Edited <a>' })
  await_request(5); reply(5)
  assert(titles.status == 'ready' and #marks() == 4, 'edit must recover automatically')
  local left = vim.api.nvim_get_current_win()
  vim.cmd.vsplit()
  move(2, 0)
  -- BufEnter can invalidate the result; complete its debounced request if needed.
  vim.wait(250, function() return false end, 10)
  if titles.status == 'pending' then reply(#requests) end
  assert(#marks(left) == 4 and #marks() == 2, 'split cursors need independent conceal')
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ns = vim.api.nvim_get_namespaces()['zettypst_titles_' .. win]
    assert(vim.deep_equal(vim.api.nvim__ns_get(ns).wins, { win }))
  end
  local before = #requests
  titles.refresh(); await_request(before + 1)
  vim.api.nvim_buf_set_lines(buf, 1, 2, false, { '@b' })
  reply(before + 1)
  assert(titles.status ~= 'ready', 'source edit must reject an in-flight response')
  await_request(before + 2); reply(before + 2)
  assert(titles.status == 'ready')
end)
vim.lsp.get_clients = get_clients
vim.fn.delete(root, 'rf')
if not ok then error(err) end
print('PASS: focus title rendering, syntax isolation, cursor/options/splits, stale responses, error recovery')
