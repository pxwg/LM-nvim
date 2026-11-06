-- Real file visits, independent of ShaDa marks and restored buffer lists.
local M = {}
local uv = vim.uv or vim.loop
local DAY = 24 * 60 * 60

function M.new(opts)
  opts = opts or {}
  local self = {
    dir = opts.dir or (vim.fn.stdpath("state") .. "/recent-files"),
    max_age = (opts.days or 30) * DAY,
    now = opts.now or os.time,
    visits = {},
  }
  -- Each instance owns its file: concurrent writers never overwrite each other.
  self.file = ("%s/%s-%s.json"):format(self.dir, uv.os_getpid(), uv.hrtime())

  function self:flush()
    if not self.dirty then
      return
    end
    local ok, err = pcall(function()
      vim.fn.mkdir(self.dir, "p")
      local cutoff = self.now() - self.max_age
      for file, visited in pairs(self.visits) do
        if visited < cutoff then
          self.visits[file] = nil
        end
      end
      local tmp = self.file .. ".tmp"
      vim.fn.writefile({ vim.json.encode(self.visits) }, tmp)
      assert(uv.fs_rename(tmp, self.file))
    end)
    if ok then
      self.dirty = false
    elseif not self.warned then
      self.warned = true
      vim.notify("Cannot save recent files: " .. tostring(err), vim.log.levels.WARN)
    end
  end

  function self:record(buf)
    local win = vim.api.nvim_get_current_win()
    if
      not vim.api.nvim_buf_is_valid(buf)
      or vim.api.nvim_win_get_buf(win) ~= buf
      or vim.bo[buf].buftype ~= ""
      or not vim.bo[buf].buflisted
      or vim.wo[win].previewwindow
      or vim.w[win].snacks_picker_preview
    then
      return
    end
    local file = vim.api.nvim_buf_get_name(buf)
    if file == "" or file:match("^%a[%w+.-]*://") then
      return
    end
    file = vim.fs.normalize(file)
    local stat = uv.fs_stat(file)
    if not stat or stat.type ~= "file" then
      return
    end
    self.visits[file] = self.now()
    self.dirty = true
    if not self.pending then
      self.pending = true
      vim.defer_fn(function()
        self.pending = false
        self:flush()
      end, 200)
    end
  end

  function self:items(filter, current_file)
    self:flush()
    local visits = {}
    local cutoff = self.now() - self.max_age
    for name, kind in vim.fs.dir(self.dir) do
      if kind == "file" and name:match("%.json$") then
        local path = self.dir .. "/" .. name
        local ok, data = pcall(function()
          return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
        end)
        if ok and type(data) == "table" then
          for file, visited in pairs(data) do
            if type(file) == "string" and type(visited) == "number" and visited >= cutoff then
              visits[file] = math.max(visits[file] or 0, visited)
            end
          end
        end
        -- Old instance files can be discarded after the whole retention window.
        local stat = uv.fs_stat(path)
        if path ~= self.file and stat and stat.mtime.sec < cutoff then
          local pid = tonumber(name:match("^(%d+)%-"))
          local _, err = nil, nil
          if pid then
            _, err = uv.kill(pid, 0)
          end
          if err and err:match("ESRCH") then
            uv.fs_unlink(path)
          end
        end
      end
    end
    for file, visited in pairs(self.visits) do
      if visited >= cutoff then
        visits[file] = math.max(visits[file] or 0, visited)
      end
    end
    local items = {}
    for file, visited in pairs(visits) do
      local item = { file = file, text = file, recent = true, visited = visited }
      if file ~= current_file and filter:match(item) then
        local stat = uv.fs_stat(file)
        if stat and stat.type == "file" then
          items[#items + 1] = item
        end
      end
    end
    table.sort(items, function(a, b)
      return a.visited > b.visited or (a.visited == b.visited and a.file < b.file)
    end)
    return items
  end

  vim.fn.mkdir(self.dir, "p")
  return self
end

function M.setup(opts)
  if M.store then
    return M.store
  end
  M.store = M.new(opts)
  local group = vim.api.nvim_create_augroup("RecentFileVisits", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group = group,
    callback = function(event)
      M.store:record(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.store:flush()
    end,
  })
  -- Only the active buffer is a visit; never seed from oldfiles or all buffers.
  M.store:record(vim.api.nvim_get_current_buf())
  return M.store
end

function M.finder(_, ctx)
  local store = M.setup()
  local current = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  return store:items(ctx.filter, current)
end

return M
