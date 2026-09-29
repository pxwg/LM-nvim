-- Project titles come from ZetTyp's evaluated announcements, never preview focus.
local M = { status = 'idle' }
local projects, surfaces, watched = {}, {}, {}
local query
local refresh, redraw

local function ranges(buf, titles)
  query = query or vim.treesitter.query.parse('typst', '(ref) @reference')
  local tree = vim.treesitter.get_parser(buf, 'typst'):parse()[1]
  local rows = {}
  for _, node in query:iter_captures(tree:root(), buf, 0, -1) do
    local text = vim.treesitter.get_node_text(node, buf)
    local title = titles[text:sub(2)]
    local row, col, last, finish = node:range()
    if title and text:sub(1, 1) == '@' and row == last then
      rows[row] = rows[row] or {}
      table.insert(rows[row], { col = col, finish = finish, title = title })
    end
  end
  return rows
end

local function remove(surface, mark)
  if vim.api.nvim_buf_is_valid(surface.buf) then
    vim.api.nvim_buf_del_extmark(surface.buf, surface.ns, mark.conceal)
    vim.api.nvim_buf_del_extmark(surface.buf, surface.ns, mark.text)
  end
end

local function reconcile(surface, desired)
  -- Read actual positions: Neovim already moved surviving marks with text edits.
  local existing = {}
  for _, mark in pairs(surface.marks) do
    local a = vim.api.nvim_buf_get_extmark_by_id(surface.buf, surface.ns, mark.conceal, { details = true })
    local b = vim.api.nvim_buf_get_extmark_by_id(surface.buf, surface.ns, mark.text, {})
    if #a > 0 and #b > 0 and a[3].end_row == a[1] and b[1] == a[1] and b[2] == a[3].end_col then
      local key = a[1] .. ':' .. a[2] .. ':' .. b[2]
      if existing[key] then remove(surface, existing[key]) end
      existing[key] = mark
    else
      remove(surface, mark)
    end
  end
  local next_marks = {}
  for key, span in pairs(desired) do
    local mark = existing[key]
    existing[key] = nil
    if not mark then
      mark = { conceal = vim.api.nvim_buf_set_extmark(surface.buf, surface.ns, span.row, span.col, {
        end_col = span.finish, conceal = '@',
      }) }
    end
    if mark.title ~= span.title then
      mark.text = vim.api.nvim_buf_set_extmark(surface.buf, surface.ns, span.row, span.finish, {
        id = mark.text,
        virt_text = { { span.title, 'Identifier' } }, virt_text_pos = 'inline', hl_mode = 'combine',
      })
      mark.title = span.title
    end
    next_marks[key] = mark
  end
  for _, mark in pairs(existing) do remove(surface, mark) end
  surface.marks = next_marks
end

redraw = function()
  for win, surface in pairs(surfaces) do
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= surface.buf then
      for _, mark in pairs(surface.marks) do remove(surface, mark) end
      surfaces[win] = nil
    end
  end
  if not vim.api.nvim__ns_set then return end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local p = watched[buf] and projects[watched[buf]]
    local desired = {}
    if p and p.titles and vim.wo[win].conceallevel >= 2 and vim.api.nvim_buf_is_loaded(buf) then
      local tick = vim.api.nvim_buf_get_changedtick(buf)
      local cached = p.buffers[buf]
      if not cached or cached.tick ~= tick then
        local ok, rows = pcall(ranges, buf, p.titles)
        cached = { tick = tick, rows = ok and rows or {} }
        p.buffers[buf] = cached
      end
      if not surfaces[win] then
        local ns = vim.api.nvim_create_namespace('zettypst_titles_' .. win)
        surfaces[win] = { ns = ns, buf = buf, marks = {} }
        vim.api.nvim__ns_set(ns, { wins = { win } })
      end
      local cursor = vim.api.nvim_win_get_cursor(win)
      local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
      if mode == 'V' or mode == '\22' then mode = 'v' end
      local focused = win == vim.api.nvim_get_current_win()
      for row, spans in pairs(cached.rows) do
        local cursor_row = focused and cursor[1] - 1 == row
        if not cursor_row or vim.wo[win].concealcursor:find(mode, 1, true) then
          for _, span in ipairs(spans) do
            local active = cursor_row and cursor[2] >= span.col and cursor[2] < span.finish
            if not active then
              desired[row .. ':' .. span.col .. ':' .. span.finish] = {
                row = row, col = span.col, finish = span.finish, title = span.title,
              }
            end
          end
        end
      end
    end
    if surfaces[win] then reconcile(surfaces[win], desired) end
  end
end

local function request(p, epoch)
  if projects[p.client.id] ~= p or epoch ~= p.epoch then return end
  local buf
  for candidate in pairs(p.client.attached_buffers) do
    if vim.api.nvim_buf_is_loaded(candidate) then buf = candidate; break end
  end
  if not buf then return end
  M.status = 'pending'
  local handle = {}
  p.pending = handle
  local ok, id = p.client:request('workspace/executeCommand', {
    command = 'zettyp.eval', arguments = { { entry = 'lsp.typ' } },
  }, function(err, result)
    if p.pending ~= handle or epoch ~= p.epoch or projects[p.client.id] ~= p then return end
    p.pending = nil
    if err then
      M.status = 'unavailable'
      -- A concurrent source update cancels queries; retry against its new generation.
      if err.code == -32801 then refresh(p) end
      return
    end
    local output = type(result) == 'table' and result.output
    local values = type(output) == 'table' and output['zk.titles']
    local data = type(values) == 'table' and values[1]
    if type(data) ~= 'table' or data.version ~= 1 or type(data.titles) ~= 'table' then
      M.status = 'unavailable'; return
    end
    local titles = {}
    for _, item in ipairs(data.titles) do
      if type(item) ~= 'table' or type(item.id) ~= 'string' or type(item.title) ~= 'string' then
        M.status = 'unavailable'; return
      end
      local title = item.title:gsub('%c', ' ')
      if title ~= '' then titles[item.id] = title end
    end
    if not vim.deep_equal(p.titles, titles) then p.titles, p.buffers = titles, {} end
    M.status = 'ready'
    redraw()
  end, buf)
  handle.id = id
  if not ok then p.pending = nil; M.status = 'unavailable'; return end
  -- Global indexing may take minutes on a cold project. Bound each request but retry.
  vim.defer_fn(function()
    if p.pending ~= handle then return end
    p.pending = nil
    p.client:cancel_request(id)
    refresh(p)
  end, 120000)
end

refresh = function(p)
  p.epoch = p.epoch + 1
  local epoch = p.epoch
  if p.pending and p.pending.id then p.client:cancel_request(p.pending.id) end
  -- Last successful titles remain visible while evaluation is pending or fails.
  -- Changed source ranges are still reparsed by changedtick before rendering.
  p.pending = nil
  M.status = 'waiting'
  vim.schedule(function()
    if epoch ~= p.epoch then return end
    redraw()
    vim.defer_fn(function() request(p, epoch) end, 180)
  end)
end

function M.refresh()
  for _, p in pairs(projects) do refresh(p) end
end

local function attach(client, buf)
  if client.name ~= 'zettyp-lsp' or not client.root_dir then return end
  local commands = (client.server_capabilities.executeCommandProvider or {}).commands or {}
  if not vim.tbl_contains(commands, 'zettyp.eval') then return end
  if not vim.uv.fs_stat(client.root_dir .. '/.zettypst/lib.typ') then return end
  local p = projects[client.id]
  if not p then
    p = { client = client, epoch = 0, buffers = {} }
    projects[client.id] = p
  end
  if watched[buf] ~= client.id then
    watched[buf] = client.id
    vim.api.nvim_buf_attach(buf, false, {
      on_lines = function() if watched[buf] == client.id then refresh(p) end end,
      on_reload = function() if watched[buf] == client.id then refresh(p) end end,
      on_detach = function() if watched[buf] == client.id then watched[buf] = nil end end,
    })
  end
  if not p.titles and not p.pending then refresh(p) else vim.schedule(redraw) end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('ZetTypstFocusTitles', { clear = true })
  vim.api.nvim_create_autocmd('LspAttach', { group = group, callback = function(e)
    local client = vim.lsp.get_client_by_id(e.data.client_id)
    if client then attach(client, e.buf) end
  end })
  vim.api.nvim_create_autocmd('LspDetach', { group = group, callback = function(e)
    local id = e.data.client_id
    if watched[e.buf] ~= id then return end
    watched[e.buf] = nil
    local p = projects[id]
    if p then
      p.buffers[e.buf] = nil
      vim.schedule(function()
        local any = false
        for _, owner in pairs(watched) do if owner == id then any = true end end
        if not any then
          if p.pending and p.pending.id then p.client:cancel_request(p.pending.id) end
          p.pending = nil
          p.epoch = p.epoch + 1
          projects[id] = nil
        end
        redraw()
      end)
    end
  end })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'CursorMoved', 'CursorMovedI',
    'ModeChanged', 'WinEnter', 'WinClosed' }, { group = group, callback = function() vim.schedule(redraw) end })
  -- Index diagnostics also signal disk/dependency updates observed by the LSP.
  -- zettyp.eval itself does not publish diagnostics, so this cannot feed back.
  vim.api.nvim_create_autocmd('DiagnosticChanged', { group = group, callback = function(e)
    local p = projects[watched[e.buf]]
    if p then refresh(p) end
  end })
  vim.api.nvim_create_autocmd({ 'BufWritePost', 'FileChangedShellPost' }, {
    group = group, callback = function(e)
      local p = projects[watched[e.buf]]
      if p then refresh(p) end
    end,
  })
  vim.api.nvim_create_autocmd('OptionSet', {
    group = group, pattern = { 'conceallevel', 'concealcursor' }, callback = redraw,
  })
  for _, client in ipairs(vim.lsp.get_clients({ name = 'zettyp-lsp' })) do
    for buf in pairs(client.attached_buffers) do attach(client, buf) end
  end
end

return M
