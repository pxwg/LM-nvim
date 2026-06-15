local porter = require("porter")

local tests = {}
local original_notify = vim.notify
local notifications = {}
vim.notify = function(message, level, opts)
  table.insert(notifications, { message = message, level = level, opts = opts })
end

local function test(name, fn)
  table.insert(tests, { name = name, fn = fn })
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function assert_same(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function assert_true(value, message)
  if value ~= true then
    error(("%s\nexpected true, got: %s"):format(message, vim.inspect(value)), 2)
  end
end

local function assert_false(value, message)
  if value ~= false then
    error(("%s\nexpected false, got: %s"):format(message, vim.inspect(value)), 2)
  end
end

local function wipe_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end
end

local function clear_registers()
  for _, register in ipairs({ '"', "0", "a" }) do
    pcall(vim.fn.setreg, register, {}, "v")
  end
end

local function tmp_path(name)
  local tmp = vim.uv.fs_realpath("/tmp") or vim.fn.fnamemodify("/tmp", ":p"):gsub("/$", "")
  return tmp .. "/" .. name
end

local function reset(routes, override_paste)
  porter._reset()
  wipe_buffers()
  clear_registers()
  notifications = {}
  porter.setup({
    override_paste = override_paste == true,
    routes = routes or {},
  })
end

local function buffer(name, filetype, lines)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(bufnr, name)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = filetype
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  return bufnr
end

local function lines(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

local function yank_line(command)
  vim.cmd.normal({ bang = true, args = { command or "yy" } })
end

local function feed(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(termcodes, "mx", false)
end

test("captures default yank metadata on the unnamed and zero registers", function()
  reset()
  buffer(tmp_path("porter-source.md"), "markdown", { "# Title", "body" })
  yank_line()

  local unnamed = porter.info('"')
  local zero = porter.info("0")

  assert_equal(unnamed.metadata.register, "0", "default paste should prefer zero-register metadata")
  assert_equal(zero.metadata.register, "0", "zero register should have metadata")
  assert_equal(zero.metadata.source.filetype, "markdown", "source filetype should be captured")
  assert_equal(zero.metadata.source.path, tmp_path("porter-source.md"), "source path should be captured")
  assert_equal(zero.metadata.source.start.line, 1, "source start line should be captured")
  assert_equal(zero.metadata.source.finish.line, 1, "source finish line should be captured")
  assert_equal(zero.metadata.regtype, "V", "linewise yank type should be captured")
end)

test("provides plug mappings and PorterInfo without overriding paste by default", function()
  reset()

  assert_equal(vim.fn.exists(":PorterInfo"), 2, "PorterInfo command should be installed")
  assert_equal(vim.fn.maparg("<Plug>(porter-paste-after)", "n") ~= "", true, "paste-after plug map should exist")
  assert_equal(vim.fn.maparg("<Plug>(porter-paste-before)", "n") ~= "", true, "paste-before plug map should exist")
  assert_equal(vim.fn.maparg("<Plug>(porter-paste-after-cursor)", "n") ~= "", true, "gp plug map should exist")
  assert_equal(vim.fn.maparg("<Plug>(porter-paste-before-cursor)", "n") ~= "", true, "gP plug map should exist")
  assert_equal(vim.fn.maparg("p", "n"), "", "setup without override should leave native p unmapped")

  vim.cmd("PorterInfo")
  assert_equal(
    vim.api.nvim_buf_get_name(0):match("porter://info/%d+$") ~= nil,
    true,
    "PorterInfo should open an info buffer"
  )
  vim.cmd("PorterInfo")
  assert_equal(vim.api.nvim_buf_get_name(0):match("porter://info/%d+$") ~= nil, true, "PorterInfo should be repeatable")
end)

test("dispatches the first matching route and restores the unnamed register", function()
  local seen_ctx

  reset({
    {
      name = "markdown-to-typst",
      from = { filetype = "markdown", buftype = "", path = { suffix = ".md" } },
      to = { filetype = "typst", buftype = "", path = { suffix = ".typ" } },
      transform = function(ctx)
        seen_ctx = vim.deepcopy(ctx)
        return {
          text = ctx.text:gsub("^#%s*", "= "),
          regtype = "V",
        }
      end,
    },
  })

  buffer(tmp_path("porter-source.md"), "markdown", { "# Title", "body" })
  yank_line()
  local saved_lines = vim.fn.getreg('"', 1, true)
  local saved_type = vim.fn.getregtype('"')

  local target = buffer(tmp_path("porter-target.typ"), "typst", { "anchor" })
  local transformed = porter.paste("p", { register = '"' })

  assert_true(transformed, "matching route should transform paste")
  assert_same(lines(target), { "anchor", "= Title" }, "transformed line should be pasted after cursor")
  assert_equal(seen_ctx.register, "0", "default yank context should use register 0")
  assert_equal(seen_ctx.regtype, "V", "ctx should preserve register type")
  assert_equal(seen_ctx.source.filetype, "markdown", "ctx should include source filetype")
  assert_equal(seen_ctx.target.filetype, "typst", "ctx should include target filetype")
  assert_equal(seen_ctx.route.name, "markdown-to-typst", "ctx should include route name")
  assert_same(vim.fn.getreg('"', 1, true), saved_lines, "unnamed register contents should be restored")
  assert_equal(vim.fn.getregtype('"'), saved_type, "unnamed register type should be restored")
end)

test("falls back to native paste when register contents no longer match metadata", function()
  local transform_count = 0

  reset({
    {
      name = "should-not-run",
      from = { filetype = "markdown" },
      to = { filetype = "typst" },
      transform = function()
        transform_count = transform_count + 1
        return "converted"
      end,
    },
  })

  buffer(tmp_path("porter-source.md"), "markdown", { "# Title" })
  yank_line()
  vim.fn.setreg('"', "changed", "V")

  local target = buffer(tmp_path("porter-target.typ"), "typst", { "anchor" })
  local transformed = porter.paste("p", { register = '"' })

  assert_false(transformed, "hash mismatch should not transform")
  assert_equal(transform_count, 0, "stale metadata should not call transform")
  assert_same(lines(target), { "anchor", "changed" }, "hash mismatch should fall back to native paste")
end)

test("falls back to native paste when no route matches", function()
  reset({
    {
      name = "markdown-to-typst",
      from = { filetype = "markdown" },
      to = { filetype = "typst" },
      transform = function()
        return "converted"
      end,
    },
  })

  buffer(tmp_path("porter-source.md"), "markdown", { "# Title" })
  yank_line()

  local target = buffer(tmp_path("porter-target.md"), "markdown", { "anchor" })
  local transformed = porter.paste("p", { register = '"' })

  assert_false(transformed, "missing route should not transform")
  assert_same(lines(target), { "anchor", "# Title" }, "missing route should use native paste")
end)

test("accepts string transform results", function()
  reset({
    {
      name = "string-result",
      from = { filetype = "markdown" },
      to = { filetype = "typst" },
      transform = function()
        return "= String"
      end,
    },
  })

  buffer(tmp_path("porter-source.md"), "markdown", { "# Title" })
  yank_line()

  local target = buffer(tmp_path("porter-target.typ"), "typst", { "anchor" })
  local transformed = porter.paste("p", { register = '"' })

  assert_true(transformed, "string transform should be accepted")
  assert_same(lines(target), { "anchor", "= String" }, "string transform should preserve source register type")
end)

test("preserves before and cursor paste command variants", function()
  reset({
    {
      name = "command-variant",
      from = { filetype = "markdown" },
      to = { filetype = "typst" },
      transform = function()
        return {
          text = "XY",
          regtype = "v",
        }
      end,
    },
  })

  buffer(tmp_path("porter-source.md"), "markdown", { "# Title" })
  yank_line()

  local before_target = buffer(tmp_path("porter-before.typ"), "typst", { "12" })
  porter.paste("P", { register = '"' })
  assert_same(lines(before_target), { "XY12" }, "P should paste before the cursor")

  local after_cursor_target = buffer(tmp_path("porter-after-cursor.typ"), "typst", { "12" })
  porter.paste("gp", { register = '"' })
  assert_same(lines(after_cursor_target), { "1XY2" }, "gp should paste after the cursor")

  local before_cursor_target = buffer(tmp_path("porter-before-cursor.typ"), "typst", { "12" })
  porter.paste("gP", { register = '"' })
  assert_same(lines(before_cursor_target), { "XY12" }, "gP should paste before the cursor")
end)

test("supports explicit registers and count", function()
  reset({
    {
      name = "markdown-to-typst",
      from = { filetype = "markdown" },
      to = { filetype = "typst" },
      transform = function(ctx)
        return {
          text = ctx.text:gsub("^#%s*", "= "),
          regtype = "V",
        }
      end,
    },
  })

  buffer(tmp_path("porter-source.md"), "markdown", { "# Explicit" })
  yank_line('"ayy')
  local saved_lines = vim.fn.getreg("a", 1, true)
  local saved_type = vim.fn.getregtype("a")

  local target = buffer(tmp_path("porter-target.typ"), "typst", { "anchor" })
  local transformed = porter.paste("p", { register = "a", count = 2 })

  assert_true(transformed, "explicit register should transform")
  assert_same(lines(target), { "anchor", "= Explicit", "= Explicit" }, "count should be passed to native paste")
  assert_same(vim.fn.getreg("a", 1, true), saved_lines, "explicit register contents should be restored")
  assert_equal(vim.fn.getregtype("a"), saved_type, "explicit register type should be restored")
end)

test("preserves blockwise register type through transform and restore", function()
  local block_type = "\0222"
  local seen_regtype

  reset({
    {
      name = "blockwise",
      from = { filetype = "markdown" },
      to = { filetype = "typst" },
      transform = function(ctx)
        seen_regtype = ctx.regtype
        return {
          text = "XX\nYY",
          regtype = ctx.regtype,
        }
      end,
    },
  })

  buffer(tmp_path("porter-source.md"), "markdown", { "aa", "bb" })
  vim.fn.setreg("a", { "aa", "bb" }, block_type)
  porter._on_yank({ operator = "y", regname = "a", inclusive = false })

  local target = buffer(tmp_path("porter-target.typ"), "typst", { "1111", "2222" })
  local transformed = porter.paste("p", { register = "a" })

  assert_true(transformed, "blockwise register should transform")
  assert_equal(seen_regtype, block_type, "ctx should expose the blockwise register type")
  assert_equal(vim.fn.getregtype("a"), block_type, "blockwise register type should be restored")
  assert_equal(#lines(target), 2, "blockwise paste should keep the target buffer usable")
end)

test("override mapping preserves explicit register and count", function()
  reset({
    {
      name = "markdown-to-typst",
      from = { filetype = "markdown" },
      to = { filetype = "typst" },
      transform = function(ctx)
        return {
          text = ctx.text:gsub("^#%s*", "= "),
          regtype = "V",
        }
      end,
    },
  }, true)

  buffer(tmp_path("porter-source.md"), "markdown", { "# Mapped" })
  yank_line('"ayy')

  local target = buffer(tmp_path("porter-target.typ"), "typst", { "anchor" })
  feed('2"ap')

  assert_same(lines(target), { "anchor", "= Mapped", "= Mapped" }, "mapped paste should preserve count and register")
end)

test("falls back to native paste when transform errors", function()
  reset({
    {
      name = "broken",
      from = { filetype = "markdown" },
      to = { filetype = "typst" },
      transform = function()
        error("boom")
      end,
    },
  })

  buffer(tmp_path("porter-source.md"), "markdown", { "# Title" })
  yank_line()

  local target = buffer(tmp_path("porter-target.typ"), "typst", { "anchor" })
  local transformed = porter.paste("p", { register = '"' })

  assert_false(transformed, "transform errors should fall back")
  assert_same(lines(target), { "anchor", "# Title" }, "transform errors should use native paste")
  assert_equal(#notifications, 1, "transform errors should notify once")
  assert_equal(notifications[1].level, vim.log.levels.ERROR, "transform error notification should use ERROR level")
end)

local failures = {}

for _, case in ipairs(tests) do
  local ok, err = xpcall(case.fn, debug.traceback)
  if ok then
    vim.api.nvim_out_write("PASS " .. case.name .. "\n")
  else
    table.insert(failures, ("FAIL %s\n%s"):format(case.name, err))
  end
end

porter._reset()
vim.notify = original_notify

if #failures > 0 then
  vim.api.nvim_err_writeln(table.concat(failures, "\n\n"))
  vim.cmd("cquit 1")
end

vim.api.nvim_out_write(("porter_spec.lua: %d tests passed\n"):format(#tests))
