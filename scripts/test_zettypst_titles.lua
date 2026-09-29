-- Run from the Neovim config root:
-- nvim --headless -u NONE -l scripts/test_zettypst_titles.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/site')
local root = vim.fn.tempname()
vim.fn.mkdir(root .. '/.zettypst', 'p')
vim.fn.mkdir(root .. '/note', 'p')
root = vim.uv.fs_realpath(root)
vim.fn.writefile({}, root .. '/.zettypst/lib.typ')
if vim.env.TYPST_PARSER then vim.treesitter.language.add('typst', { path = vim.env.TYPST_PARSER }) end
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(buf, root .. '/note/a.typ')
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  '= Current <a>', '@b @b @section', '```typst', '@b', '```', '// @b',
})
vim.wo.conceallevel = 2
vim.wo.concealcursor = 'nc'
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local requests = {}
local client = { id = 1, root_dir = root, name = 'zettyp-lsp', attached_buffers = { [buf] = true },
  server_capabilities = { executeCommandProvider = { commands = { 'zettyp.eval' } } } }
function client:request(method, params, callback)
  assert(method == 'workspace/executeCommand')
  assert(params.command == 'zettyp.eval')
  assert(params.arguments[1].entry == 'lsp.typ')
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
local function reply(n, version, title)
  requests[n](nil, { revision = n, output = { ['zk.titles'] = { {
    version = version or 1, titles = { { id = 'b', title = title or '中文 title' } },
  } } } })
end
local function marks(win)
  local ns = vim.api.nvim_get_namespaces()['zettypst_titles_' .. (win or vim.api.nvim_get_current_win())]
  return ns and vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true }) or {}
end
local function move(row, col)
  vim.api.nvim_win_set_cursor(0, { row, col })
  vim.api.nvim_exec_autocmds('CursorMoved', {})
  vim.wait(20, function() return false end, 5)
end
local ops = { set = 0, del = 0, clear = 0 }
local originals = {}
for short, name in pairs({ set = 'nvim_buf_set_extmark', del = 'nvim_buf_del_extmark', clear = 'nvim_buf_clear_namespace' }) do
  originals[name] = vim.api[name]
  vim.api[name] = function(...)
    ops[short] = ops[short] + 1
    return originals[name](...)
  end
end
local ok, err = pcall(function()
  titles.setup()
  await_request(1); reply(1)
  assert(titles.status == 'ready')
  assert(#marks() == 4, 'only two actual references should be decorated')
  local stable = vim.deepcopy(ops)
  move(1, 1); move(1, 2)
  assert(vim.deep_equal(stable, ops), 'ordinary cursor movement must perform zero extmark writes')
  move(2, 0)
  assert(#marks() == 2, 'cursor must reveal only its reference')
  assert(ops.del == stable.del + 2 and ops.set == stable.set, 'only entered reference is removed')
  move(1, 0)
  vim.wo.conceallevel = 0
  vim.api.nvim_exec_autocmds('OptionSet', { pattern = 'conceallevel' })
  assert(#marks() == 0, 'no virtual title when conceal is disabled')
  vim.wo.conceallevel = 2
  titles.refresh(); await_request(2)
  titles.refresh(); await_request(3)
  reply(2, 1, 'stale')
  assert(titles.status == 'pending' and #marks() == 4, 'cancelled response must preserve last success')
  reply(3, 99)
  assert(titles.status == 'unavailable' and #marks() == 4, 'unsupported output must preserve last success')
  titles.refresh(); await_request(4)
  requests[4]({ message = 'compile failure' })
  assert(titles.status == 'unavailable' and #marks() == 4)
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { '= Edited <a>' })
  await_request(5); reply(5)
  assert(titles.status == 'ready' and #marks() == 4, 'edit must recover automatically')
  local left = vim.api.nvim_get_current_win()
  local before_switch = #requests
  vim.cmd.vsplit()
  move(2, 0)
  vim.wait(250, function() return false end, 10)
  assert(#requests == before_switch, 'window switching must not request evaluation')
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
  move(1, 0)
  local before_marks = marks(left)
  local stable_ops = vim.deepcopy(ops)
  titles.refresh(); await_request(before + 3)
  assert(vim.deep_equal(stable_ops, ops), 'pending evaluation must not touch stable marks')
  reply(before + 3)
  assert(vim.deep_equal(stable_ops, ops), 'identical titles must perform zero writes')
  titles.refresh(); await_request(before + 4)
  reply(before + 4, 1, 'Updated title')
  local after_marks = marks(left)
  assert(#before_marks == #after_marks)
  for i, m in ipairs(before_marks) do assert(m[1] == after_marks[i][1], 'title changes preserve IDs') end
  assert(ops.del == stable_ops.del and ops.set == stable_ops.set + 2, 'only two virtual text marks updated')
  stable_ops = vim.deepcopy(ops)
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, { '// inserted above references' })
  await_request(before + 5); reply(before + 5, 1, 'Updated title')
  assert(vim.deep_equal(stable_ops, ops), 'moved surviving references reuse auto-shifted extmarks')
  assert(ops.clear == 0, 'never clear a complete namespace')
end)
for name, original in pairs(originals) do vim.api[name] = original end
vim.lsp.get_clients = get_clients
vim.fn.delete(root, 'rf')
if not ok then error(err) end
print('PASS: eval title rendering, syntax isolation, cursor/options/splits, stale responses, error recovery')
