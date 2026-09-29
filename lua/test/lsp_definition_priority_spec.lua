-- Run with: nvim --clean --headless -l lua/test/lsp_definition_priority_spec.lua
package.path = './lua/?.lua;' .. package.path
local clients = { [1] = { name = 'tinymist' }, [2] = { name = 'zettyp-lsp' } }
vim.lsp.get_client_by_id = function(id) return clients[id] end
local location = { uri = 'file:///note.typ', range = {} }
local responses
local context = {}
local cancel = function() end
vim.lsp.buf_request_all = function(_, _, _, cb)
  cb(responses, context)
  return cancel
end
local source = {}
local streamed
source.request = function(_, _, _, cb)
  for _, entry in ipairs(streamed) do cb(clients[entry[1]], entry[2], context) end
end
package.loaded['snacks.picker.source.lsp'] = source
local priority = require('util.lsp_definition_priority')
priority.setup()
priority.setup()
priority.setup_snacks()
priority.setup_snacks()

for _, result in ipairs({ { location }, location, {}, false }) do
  for _, err in ipairs({ false, { message = 'failed' } }) do
    responses = { [1] = { result = { location } }, [2] = { result = result, err = err } }
    local exclusive = result ~= false and next(result) ~= nil and not err
    local returned = vim.lsp.buf_request_all(0, 'textDocument/definition', {}, function(filtered, ctx)
      assert(ctx == context)
      assert((filtered[1] == nil) == exclusive)
      assert(filtered[2] == responses[2])
      if not exclusive then assert(filtered == responses) end
    end)
    assert(returned == cancel)
    vim.lsp.buf_request_all(0, 'textDocument/references', {}, function(filtered)
      assert(filtered == responses)
    end)
  end
end

for _, result in ipairs({ { location }, location, {} }) do
  for _, reverse in ipairs({ false, true }) do
    streamed = { { 1, { location } }, { 2, result } }
    if reverse then streamed = { streamed[2], streamed[1] } end
    for _, method in ipairs({ 'textDocument/definition', 'textDocument/references', 'textDocument/typeDefinition' }) do
      local seen = {}
      source.request(0, method, {}, function(client, _, params)
        assert(params == context)
        seen[#seen + 1] = client.name
      end)
      if method == 'textDocument/definition' and next(result) then
        assert(#seen == 1 and seen[1] == 'zettyp-lsp')
      else
        assert(#seen == 2)
      end
    end
  end
end
-- Exercise the real Snacks executor (uv check / fast event), not a mock.
vim.opt.rtp:append(vim.fn.expand('~/.local/share/nvim/lazy/snacks.nvim'))
local Async = require('snacks.picker.util.async')
local failure
local completed = false
local seen = 0
streamed = { { 1, { location } }, { 2, { location } } }
local task = Async.new(function()
  assert(vim.in_fast_event(), 'regression must run in a fast event')
  source.request(0, 'textDocument/definition', {}, function(client)
    assert(not vim.in_fast_event(), 'definition callback must run on main loop')
    assert(client.name == 'zettyp-lsp')
    vim.fn.bufadd('/tmp/lsp-definition-priority-test.typ')
    seen = seen + 1
  end)
  assert(seen == 1, 'request must wait for replay before returning')
  completed = true
end)
task:on('error', function(err) failure = err end)
assert(vim.wait(2000, function() return completed or failure ~= nil end), 'async test timed out')
assert(not failure, failure)
assert(completed)
print('lsp_definition_priority: all tests passed (including real fast-event executor)')
