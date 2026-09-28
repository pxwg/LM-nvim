-- Focus owns semantic titles; this module only queries and decorates source refs.
local M = {}
local surfaces = {}
local generation, state, pending = 0, nil, nil
local watched = {}
local query
M.status = 'idle'

local function current()
  local buf = vim.api.nvim_get_current_buf()
  local root, id = require('util.zettypst_focus').note(vim.api.nvim_buf_get_name(buf))
  if not root then return end
  for _, client in ipairs(vim.lsp.get_clients({ name = 'tinymist', bufnr = buf })) do
    if client.root_dir == root and client._zettyp_focus == id then
      return buf, root, id, client
    end
  end
end

local function redraw()
  for _, surface in pairs(surfaces) do
    if vim.api.nvim_buf_is_valid(surface.buf) then
      vim.api.nvim_buf_clear_namespace(surface.buf, surface.ns, 0, -1)
    end
  end
  if not state or vim.api.nvim_get_current_buf() ~= state.buf
    or not vim.api.nvim_buf_is_valid(state.buf)
    or vim.api.nvim_buf_get_changedtick(state.buf) ~= state.tick
    or not vim.api.nvim__ns_set then return end
  for _, win in ipairs(vim.fn.win_findbuf(state.buf)) do
    if vim.wo[win].conceallevel >= 2 then
      local surface = surfaces[win]
      if not surface then
        surface = { ns = vim.api.nvim_create_namespace('zettypst_titles_' .. win), buf = state.buf }
        surfaces[win] = surface
      end
      surface.buf = state.buf
      vim.api.nvim__ns_set(surface.ns, { wins = { win } })
      local cursor = vim.api.nvim_win_get_cursor(win)
      local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
      if mode == 'V' or mode == '\\22' then mode = 'v' end
      for row, spans in pairs(state.rows) do
        local cursor_row = cursor[1] - 1 == row
        if not cursor_row or vim.wo[win].concealcursor:find(mode, 1, true) then
          for _, span in ipairs(spans) do
            local active = cursor_row and cursor[2] >= span.col and cursor[2] < span.end_col
            if not active then
              vim.api.nvim_buf_set_extmark(state.buf, surface.ns, row, span.col, {
                end_col = span.end_col, conceal = '@',
              })
              vim.api.nvim_buf_set_extmark(state.buf, surface.ns, row, span.end_col, {
                virt_text = { { span.title, 'Identifier' } }, virt_text_pos = 'inline', hl_mode = 'combine',
              })
            end
          end
        end
      end
    end
  end
end

local function ranges(buf, titles)
  query = query or vim.treesitter.query.parse('typst', '(ref) @reference')
  local tree = vim.treesitter.get_parser(buf, 'typst'):parse()[1]
  local rows = {}
  for _, node in query:iter_captures(tree:root(), buf, 0, -1) do
    local text = vim.treesitter.get_node_text(node, buf)
    local title = titles[text:sub(2)]
    local row, col, end_row, end_col = node:range()
    if title and text:sub(1, 1) == '@' and row == end_row then
      rows[row] = rows[row] or {}
      rows[row][#rows[row] + 1] = { col = col, end_col = end_col, title = title }
    end
  end
  return rows
end

local function request(epoch)
  if epoch ~= generation then return end
  local buf, root, id, client = current()
  if not buf then M.status = 'idle'; return end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  M.status = 'pending'
  local handle = { client = client }
  pending = handle
  local ok, request_id = client:request('workspace/executeCommand', {
    command = 'tinymist.exportQuery',
    arguments = { root .. '/focus.typ', {
      format = 'json', selector = '<zettypst-focus-titles>', field = 'value', one = true,
    }, { write = false, open = false } },
  }, function(err, result)
    if pending == handle then pending = nil end
    if epoch ~= generation then return end
    local now, _, selected, active_client = current()
    if now ~= buf or selected ~= id or active_client ~= client
      or not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_changedtick(buf) ~= tick then return end
    if err or not result or type(result.data) ~= 'string' then
      M.status = 'unavailable' -- Source stays visible; the next edit retries.
      return
    end
    local decoded, data = pcall(function() return vim.json.decode(vim.base64.decode(result.data)) end)
    if not decoded or type(data) ~= 'table' or data.version ~= 1 or data.focus ~= id
      or type(data.titles) ~= 'table' then M.status = 'unavailable'; return end
    local titles = {}
    for _, item in ipairs(data.titles) do
      if type(item) ~= 'table' or type(item.id) ~= 'string' or type(item.title) ~= 'string' then
        M.status = 'unavailable'; return
      end
      local title = item.title:gsub('%c', ' ')
      if title ~= '' then titles[item.id] = title end
    end
    local parsed, rows = pcall(ranges, buf, titles)
    if not parsed then M.status = 'unavailable'; return end
    state = { buf = buf, tick = tick, rows = rows }
    M.status = 'ready'
    redraw()
  end, buf)
  handle.id = request_id
  if not ok then pending = nil; M.status = 'unavailable'; return end
  vim.defer_fn(function()
    if pending ~= handle then return end
    pending = nil
    generation = generation + 1
    client:cancel_request(request_id)
    M.status = 'timeout'
  end, 10000)
end

function M.refresh()
  generation = generation + 1
  local epoch = generation
  state = nil
  M.status = 'waiting'
  if pending then
    if pending.id then pending.client:cancel_request(pending.id) end
    pending = nil
  end
  -- on_lines can run under textlock. Never parse, query or redraw inside it.
  vim.schedule(function()
    if epoch ~= generation then return end
    redraw()
    vim.defer_fn(function() request(epoch) end, 180)
  end)
end

local function watch(buf)
  if watched[buf] then return end
  watched[buf] = vim.api.nvim_buf_attach(buf, false, {
    on_lines = function() M.refresh() end,
    on_reload = function() M.refresh() end,
    on_detach = function() watched[buf] = nil; M.refresh() end,
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup('ZetTypstFocusTitles', { clear = true })
  vim.api.nvim_create_autocmd('LspAttach', { group = group, callback = function(e)
    local client = vim.lsp.get_client_by_id(e.data.client_id)
    if client and client.name == 'tinymist' and client.root_dir
      and vim.uv.fs_stat(client.root_dir .. '/.zettypst/focus.typ') then
      watch(e.buf)
      M.refresh()
    end
  end })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'FileChangedShellPost' }, {
    group = group, callback = M.refresh,
  })
  vim.api.nvim_create_autocmd('LspDetach', { group = group, callback = M.refresh })
  -- Window-scoped namespaces keep independent cursor/conceal choices in splits.
  -- Unsupported Neovim versions simply retain source instead of duplicating text.
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'ModeChanged', 'WinEnter', 'WinClosed' }, {
    group = group, callback = redraw,
  })
  vim.api.nvim_create_autocmd('OptionSet', {
    group = group, pattern = { 'conceallevel', 'concealcursor' }, callback = redraw,
  })
  for _, client in ipairs(vim.lsp.get_clients({ name = 'tinymist' })) do
    if client.root_dir and vim.uv.fs_stat(client.root_dir .. '/.zettypst/focus.typ') then
      for buf in pairs(client.attached_buffers) do watch(buf) end
    end
  end
  M.refresh()
end

return M
