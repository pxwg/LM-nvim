-- Run with: nvim --clean --headless -l lua/test/note_info_spec.lua
package.path = './lua/?.lua;' .. package.path
local root = vim.fn.tempname()
vim.fn.mkdir(root .. '/note', 'p')
local ids = { '2604040041', '20260404T004100' }
for _, id in ipairs(ids) do
  vim.fn.writefile({
    '#import "../include.typ": *',
    '= Test title <' .. id .. '>',
    '#tag.test',
    'aliases = ("Alias",)',
    'abstract = "Summary"',
    'keywords = ("keyword",)',
    'See @2604040042',
  }, root .. '/note/' .. id .. '.typ')
end

local system = vim.system
vim.system = function() error('note metadata must never spawn a process') end
local reader = require('util.note_info')
local function check()
  for _, id in ipairs(ids) do
    local note = assert(reader.note_info_by_file('note/' .. id .. '.typ', {
      cwd = root,
      include_references = true,
    }))
    assert(note.id == id and note.title == 'Test title')
    assert(note.title_line == 2 and note.path == root .. '/note/' .. id .. '.typ')
    assert(note.tags[1] == 'test' and note.aliases[1] == 'Alias')
    assert(note.abstract == 'Summary' and note.keywords[1] == 'keyword')
    assert(note.references['2604040042'])
    assert(note._source == 'local')
  end
  assert(reader.note_info_by_file('https://example.com/note/2604040041.typ') == nil)
  assert(reader.note_info_by_file(root .. '/note/123.typ') == nil)
  assert(reader.note_info_by_file(root .. '/other.typ') == nil)
end
check()

-- Read changed files without stale persistent metadata.
vim.fn.writefile({ '= New title <2604040041>' }, root .. '/note/2604040041.typ')
assert(reader.note_info_by_file(root .. '/note/2604040041.typ').title == 'New title')

local done, failure = false, nil
local timer = vim.uv.new_timer()
timer:start(0, 0, function()
  local ok, err = pcall(function()
    assert(vim.in_fast_event())
    for _, id in ipairs(ids) do
      assert(reader.note_info_by_file(root .. '/note/' .. id .. '.typ'))
    end
  end)
  failure = not ok and err or nil
  timer:close()
  done = true
end)
assert(vim.wait(2000, function() return done end), 'fast-event read timed out')
vim.system = system
vim.fn.delete(root, 'rf')
assert(not failure, failure)
print('note_info: OK')
