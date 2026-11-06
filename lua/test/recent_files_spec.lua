-- Run with: nvim --clean --headless -l lua/test/recent_files_spec.lua
package.path = "./lua/?.lua;" .. package.path
local recent = require("util.recent_files")
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
root = assert(vim.uv.fs_realpath(root))
local now = 2000000000
local function file(name)
  local path = root .. "/" .. name
  vim.fn.writefile({ name }, path)
  return path
end
local a, b, old, deleted = file("a"), file("b"), file("old"), file("deleted")
local dir = root .. "/history"
local one = recent.new({
  dir = dir,
  now = function()
    return now
  end,
})
local two = recent.new({
  dir = dir,
  now = function()
    return now
  end,
})
local filter = {
  match = function()
    return true
  end,
}
one.visits = { [a] = now - 2, [old] = now - 31 * 86400, [deleted] = now }
one.dirty = true
one:flush()
two.visits = { [a] = now - 1, [b] = now }
two.dirty = true
two:flush()
vim.fn.delete(deleted)
-- An invalid shard must not hide otherwise valid history.
vim.fn.writefile({ "invalid" }, dir .. "/broken.json")
local items = one:items(filter)
assert(#items == 2 and items[1].file == b and items[2].file == a)
assert(items[2].visited == now - 1, "merge must keep latest visit")
assert(#one:items(filter, b) == 1, "exclude current file")
assert(#one:items({
  match = function(_, item)
    return item.file == a
  end,
}) == 1)
-- Reloading from disk preserves visits without seeding from oldfiles.
local fresh = recent.new({
  dir = dir,
  now = function()
    return now
  end,
})
assert(#fresh:items(filter) == 2)
vim.v.oldfiles = { old }
assert(#fresh:items(filter) == 2)

local tracker = recent.setup({
  dir = root .. "/events",
  now = function()
    return now
  end,
})
vim.cmd.edit(vim.fn.fnameescape(a))
assert(tracker.visits[a] == now, "BufEnter records real edit")
now = now + 1
vim.w.snacks_picker_preview = true
vim.cmd.edit(vim.fn.fnameescape(b))
assert(tracker.visits[b] == nil, "picker preview must not count")
vim.w.snacks_picker_preview = nil
vim.api.nvim_exec_autocmds("BufEnter", { buffer = 0 })
assert(tracker.visits[b] == now, "confirmed file can count after preview")
now = now + 1
vim.wo.previewwindow = true
vim.api.nvim_exec_autocmds("BufEnter", { buffer = 0 })
assert(tracker.visits[b] == now - 1, "preview windows must not count")
vim.wo.previewwindow = false
vim.bo.buflisted = false
vim.api.nvim_exec_autocmds("BufEnter", { buffer = 0 })
assert(tracker.visits[b] == now - 1, "unlisted buffers must not count")
vim.bo.buflisted = true
-- A saved new file starts counting once it actually exists.
local created = root .. "/created"
vim.cmd.edit(vim.fn.fnameescape(created))
assert(tracker.visits[created] == nil)
vim.cmd.write()
assert(tracker.visits[created] == now)
tracker:flush()
assert(#tracker:items(filter) == 3)
-- Resolve the actual plugin spec through Snacks, including its default paths.
vim.opt.rtp:append(vim.fn.expand("~/.local/share/nvim/lazy/snacks.nvim"))
local spec = assert(loadfile("lua/plugins/ui.snacks.nvim.lua"))()
require("snacks").setup({ picker = vim.tbl_deep_extend("force", spec.opts.picker, { enabled = false }) })
local config = require("snacks.picker.config")
local resolved = config.get({ source = "recent", filter = { cwd = root } })
assert(type(resolved.finder) == "function")
assert(resolved.matcher.frecency == false and resolved.matcher.sort_empty == false)
local actual_filter = require("snacks.picker.core.filter").new({ opts = resolved })
local picked = config.finder(resolved.finder)(resolved, { filter = actual_filter })
assert(#picked == 2, "real finder excludes current file and keeps cwd candidates")
for _, item in ipairs(picked) do
  assert(item.file == a or item.file == b)
end
local outside = require("snacks.picker.core.filter").new({
  opts = config.get({ source = "recent", filter = { cwd = root .. "/other" } }),
})
assert(#recent.finder({}, { filter = outside }) == 0, "cwd restriction must survive config merging")
now = now + 31 * 86400
assert(#tracker:items(filter) == 0, "visits expire after 30 days")
-- Clear exit handlers and allow pending writes before removing the fixture.
vim.wait(250, function()
  return not tracker.pending
end)
vim.api.nvim_del_augroup_by_name("RecentFileVisits")
vim.fn.delete(root, "rf")
print("recent_files: passed")
