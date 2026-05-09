local M = {}

local uv = vim.uv or vim.loop

local state = {
  current_workspace_id = nil,
  workspaces = {},
  thread_bindings = {},
  snapshots = {},
  proposals = {},
  review_feedback = {},
  rpc_sync = {},
  last_attachment = {},
  setup_done = false,
  hooks_registered = false,
}

local REVIEW_NAMESPACE = vim.api.nvim_create_namespace("alma_zk_blackboard_review")
local REVIEW_STATES = {
  pending = true,
  approved = true,
  rejected = true,
  commented = true,
  stale = true,
  applied = true,
}

local DEFAULT_WIKI_ROOT = vim.fs.normalize((uv.os_homedir() or vim.fn.expand("~")) .. "/wiki")
local MAX_SCANNED_FILES = 500

local function notify(message, level)
  vim.notify("[zk-alma] " .. message, level or vim.log.levels.INFO)
end

local function now_iso()
  local raw = os.date("%Y-%m-%dT%H:%M:%S%z")
  return raw:gsub("([+-]%d%d)(%d%d)$", "%1:%2")
end

local function timestamp_stem()
  return os.date("%Y%m%dT%H%M%S") .. "-" .. tostring(math.floor((uv.hrtime() % 1000000000) / 1000000))
end

local function sanitize_segment(value)
  value = tostring(value or "unknown"):gsub("[^%w%._%-]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
  if value == "" then
    return "unknown"
  end
  return value:sub(1, 96)
end

local function normalize_path(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end
  if path:match("^%w+://") then
    return nil
  end
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function wiki_root()
  return vim.fs.normalize(vim.g.zk_alma_wiki_root or DEFAULT_WIKI_ROOT)
end

local function current_dir()
  local cwd = vim.fn.getcwd()
  if type(cwd) == "string" and cwd ~= "" then
    return cwd
  end
  return uv.cwd()
end

local function path_join(...)
  return table.concat({ ... }, "/"):gsub("/+", "/")
end

local function file_exists(path)
  return type(path) == "string" and path ~= "" and uv.fs_stat(path) ~= nil
end

local function path_is_under(root, path)
  if type(root) ~= "string" or type(path) ~= "string" then
    return false
  end
  root = root:gsub("/+$", "")
  path = path:gsub("/+$", "")
  return path == root or path:sub(1, #root + 1) == root .. "/"
end

local function is_absolute_path(path)
  return type(path) == "string" and (path:sub(1, 1) == "/" or path:match("^%a:[/\\]") ~= nil)
end

local function relative_to_root(root, path)
  if type(root) ~= "string" or type(path) ~= "string" then
    return nil
  end
  root = root:gsub("/+$", "")
  path = path:gsub("/+$", "")
  if path == root then
    return "."
  end
  if path:sub(1, #root + 1) == root .. "/" then
    return path:sub(#root + 2)
  end
  return nil
end

local function split_lines(text)
  if type(text) ~= "string" or text == "" then
    return {}
  end
  local lines = vim.split(text:gsub("\r\n", "\n"), "\n", { plain = true })
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

local function table_count(list)
  return type(list) == "table" and #list or 0
end

local function tables_equal(left, right)
  if table_count(left) ~= table_count(right) then
    return false
  end
  for i = 1, #left do
    if left[i] ~= right[i] then
      return false
    end
  end
  return true
end

local function decode_json(raw)
  if type(raw) ~= "string" or raw == "" then
    return nil
  end
  local ok, decoded = pcall(vim.json.decode, raw)
  if ok and type(decoded) == "table" then
    return decoded
  end
  return nil
end

local function run_zk_lsp(args, opts)
  opts = opts or {}
  local command = vim.list_extend({ "zk-lsp" }, args)
  local result = vim
    .system(command, {
      text = true,
      cwd = opts.cwd or wiki_root(),
    })
    :wait()

  if result.code == 0 then
    return result.stdout or ""
  end

  return nil, (result.stderr or ""):gsub("%s+$", "")
end

local function fallback_workspace(id)
  if type(id) ~= "string" or id == "" then
    return nil
  end

  local root = path_join(wiki_root(), "workspace", id)
  local note_dir = path_join(root, "note")
  local manifest = path_join(root, "workspace.toml")

  if not file_exists(root) and not file_exists(manifest) then
    return nil
  end

  return {
    id = id,
    title = id,
    status = "unknown",
    topic = "",
    root = root,
    note_dir = note_dir,
    manifest = manifest,
    paths = {
      root = root,
      note_dir = note_dir,
      manifest_file = manifest,
      link_file = path_join(root, "link.typ"),
      include_file = path_join(root, "include.typ"),
      index_file = path_join(root, "index.typ"),
    },
    notes = {},
    source = "fallback",
  }
end

local function normalize_workspace(raw)
  if type(raw) ~= "table" then
    return nil
  end

  local paths = type(raw.paths) == "table" and raw.paths or {}
  local id = raw.id or raw.workspace_id or raw.workspace
  local root = paths.root or raw.root
  local note_dir = paths.note_dir or raw.note_dir
  local manifest = paths.manifest_file or raw.manifest or raw.manifest_file

  if type(id) ~= "string" or id == "" then
    return nil
  end

  root = normalize_path(root or path_join(wiki_root(), "workspace", id))
  note_dir = normalize_path(note_dir or path_join(root, "note"))
  manifest = normalize_path(manifest or path_join(root, "workspace.toml"))

  return {
    id = id,
    title = raw.title or id,
    status = raw.status or "unknown",
    topic = raw.topic or "",
    root = root,
    note_dir = note_dir,
    manifest = manifest,
    paths = {
      root = root,
      note_dir = note_dir,
      manifest_file = manifest,
      link_file = normalize_path(paths.link_file or path_join(root, "link.typ")),
      include_file = normalize_path(paths.include_file or path_join(root, "include.typ")),
      index_file = normalize_path(paths.index_file or path_join(root, "index.typ")),
    },
    notes = type(raw.notes) == "table" and vim.deepcopy(raw.notes) or {},
    source = raw.source or "zk-lsp",
  }
end

local function describe_workspace(id, opts)
  opts = opts or {}
  if type(id) ~= "string" or id == "" then
    return nil, "workspace id is required"
  end

  local stdout, err = run_zk_lsp({ "workspace", "describe", id, "--json" }, opts)
  local decoded = decode_json(stdout)
  local workspace = normalize_workspace(decoded)
  if workspace then
    return workspace
  end

  workspace = fallback_workspace(id)
  if workspace then
    return workspace
  end

  return nil, err ~= "" and err or ("workspace not found: " .. id)
end

local function detect_workspace_id(path)
  if type(path) ~= "string" or path == "" then
    path = vim.api.nvim_buf_get_name(0)
  end
  if type(path) ~= "string" or path == "" then
    path = current_dir()
  end
  path = normalize_path(path)
  if not path then
    return nil
  end

  local stdout = run_zk_lsp({ "workspace", "detect", "--path", path, "--json" })
  local decoded = decode_json(stdout)
  if decoded and type(decoded.workspace_id) == "string" and decoded.workspace_id ~= "" then
    return decoded.workspace_id
  end

  local prefix = wiki_root():gsub("/+$", "") .. "/workspace/"
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1):match("^([^/]+)")
  end
  return nil
end

local function list_workspace_ids()
  local stdout = run_zk_lsp({ "workspace", "list", "--json" })
  local decoded = decode_json(stdout)
  if decoded and type(decoded.workspaces) == "table" then
    local ids = {}
    for _, workspace in ipairs(decoded.workspaces) do
      if type(workspace) == "table" and type(workspace.id) == "string" then
        table.insert(ids, workspace.id)
      end
    end
    table.sort(ids)
    return ids
  end

  stdout = run_zk_lsp({ "workspace", "list" })
  local ids = {}
  for line in tostring(stdout or ""):gmatch("[^\r\n]+") do
    if line ~= "" then
      table.insert(ids, line)
    end
  end

  local workspace_root = path_join(wiki_root(), "workspace")
  local fs = uv.fs_scandir(workspace_root)
  if fs then
    while true do
      local name, kind = uv.fs_scandir_next(fs)
      if not name then
        break
      end
      if kind == "directory" and name:match("^[a-z0-9][a-z0-9%-]*$") then
        table.insert(ids, name)
      end
    end
  end

  table.sort(ids)
  local seen = {}
  local out = {}
  for _, id in ipairs(ids) do
    if not seen[id] then
      seen[id] = true
      table.insert(out, id)
    end
  end
  return out
end

local function workspace_for_id(id)
  if state.workspaces[id] then
    return state.workspaces[id]
  end
  local workspace = describe_workspace(id, { silent = true })
  if workspace then
    state.workspaces[id] = workspace
    return workspace
  end
  return nil
end

local function diff_header_path(diff)
  for _, line in ipairs(split_lines(diff)) do
    local path = line:match("^%+%+%+%s+([^%s]+)")
    if path and path ~= "/dev/null" then
      return path:gsub("^b/", "")
    end
  end
  for _, line in ipairs(split_lines(diff)) do
    local path = line:match("^%-%-%-%s+([^%s]+)")
    if path and path ~= "/dev/null" then
      return path:gsub("^a/", "")
    end
  end
  return nil
end

local function parse_hunk_count(raw)
  if raw == nil or raw == "" then
    return 1
  end
  return tonumber(raw) or 1
end

local function parse_hunk_header(line)
  local old_start, old_count, new_start, new_count, tail =
    line:match("^@@%s+%-(%d+),?(%d*)%s+%+(%d+),?(%d*)%s+@@(.*)$")
  if not old_start then
    return nil
  end
  return {
    old_start = tonumber(old_start),
    old_count = parse_hunk_count(old_count),
    new_start = tonumber(new_start),
    new_count = parse_hunk_count(new_count),
    section = vim.trim(tail or ""),
  }
end

local function classify_hunk(hunk)
  local adds = table_count(hunk.added_lines)
  local deletes = table_count(hunk.removed_lines)
  if adds > 0 and deletes > 0 then
    return "replacement"
  elseif adds > 0 then
    return "addition"
  elseif deletes > 0 then
    return "deletion"
  end
  return "context"
end

local function finalize_hunk(hunk)
  if not hunk then
    return nil
  end

  hunk.kind = classify_hunk(hunk)
  hunk.old_text = {}
  hunk.new_text = {}
  for _, line in ipairs(hunk.lines) do
    local marker = line:sub(1, 1)
    local text = line:sub(2)
    if marker == " " or marker == "-" then
      table.insert(hunk.old_text, text)
    end
    if marker == " " or marker == "+" then
      table.insert(hunk.new_text, text)
    end
  end
  return hunk
end

local function parse_unified_diff(diff)
  local hunks = {}
  local current

  for _, line in ipairs(split_lines(diff)) do
    local header = parse_hunk_header(line)
    if header then
      if current then
        table.insert(hunks, finalize_hunk(current))
      end
      current = vim.tbl_extend("force", header, {
        header = line,
        lines = {},
        added_lines = {},
        removed_lines = {},
      })
    elseif current then
      local marker = line:sub(1, 1)
      if marker == " " or marker == "+" or marker == "-" then
        table.insert(current.lines, line)
        if marker == "+" then
          table.insert(current.added_lines, line:sub(2))
        elseif marker == "-" then
          table.insert(current.removed_lines, line:sub(2))
        end
      elseif line:sub(1, 1) == "\\" then
        current.no_newline_marker = line
      end
    end
  end

  if current then
    table.insert(hunks, finalize_hunk(current))
  end

  return hunks
end

local function workspace_for_thread(thread_id)
  local binding = state.thread_bindings[thread_id]
  if type(binding) ~= "table" then
    return nil
  end
  return workspace_for_id(binding.workspace_id)
end

local function proposal_workspace(thread_id)
  return workspace_for_thread(thread_id) or (state.current_workspace_id and workspace_for_id(state.current_workspace_id)) or nil
end

local function proposal_file_path(file, workspace)
  if type(file) ~= "table" then
    return nil, nil
  end

  local diff_path = diff_header_path(file.diff)
  local relative_path = file.relative_path or file.relativePath or file.relpath or diff_path
  local raw_path = file.path or file.file or file.filename or file.name
  local root = workspace and workspace.root or current_dir()
  local path

  if is_absolute_path(raw_path) then
    path = normalize_path(raw_path)
  elseif type(relative_path) == "string" and relative_path ~= "" then
    path = normalize_path(path_join(root, relative_path))
  elseif type(raw_path) == "string" and raw_path ~= "" then
    path = normalize_path(path_join(root, raw_path))
    relative_path = raw_path
  end

  if path and (type(relative_path) ~= "string" or relative_path == "") and workspace then
    relative_path = relative_to_root(workspace.root, path)
  end

  return path, relative_path
end

local function proposal_id_from_payload(proposal)
  local id = proposal.id or proposal.proposal_id or proposal.proposalId or proposal.change_id or proposal.changeId
  if type(id) == "string" and id ~= "" then
    return id
  end
  return "proposal-" .. timestamp_stem()
end

local function proposal_files_from_payload(proposal)
  if type(proposal.files) == "table" then
    return proposal.files
  end
  if type(proposal.changes) == "table" then
    return proposal.changes
  end
  if type(proposal.diffs) == "table" then
    return proposal.diffs
  end
  if type(proposal.patches) == "table" then
    return proposal.patches
  end
  if type(proposal.diff) == "string" or type(proposal.patch) == "string" or type(proposal.unified_diff) == "string" then
    return { proposal }
  end
  return {}
end

local function hunk_diff_text(hunk)
  local lines = { hunk.header }
  vim.list_extend(lines, hunk.lines or {})
  return table.concat(lines, "\n")
end

local function all_proposal_hunks()
  local hunks = {}
  local ids = vim.tbl_keys(state.proposals)
  table.sort(ids)
  for _, proposal_id in ipairs(ids) do
    local proposal = state.proposals[proposal_id]
    for _, hunk in ipairs(proposal.hunks or {}) do
      table.insert(hunks, hunk)
    end
  end
  table.sort(hunks, function(a, b)
    if a.path == b.path then
      if a.anchor_line == b.anchor_line then
        return a.id < b.id
      end
      return (a.anchor_line or 0) < (b.anchor_line or 0)
    end
    return tostring(a.path) < tostring(b.path)
  end)
  return hunks
end

local function find_hunk(hunk_id, proposal_id)
  if type(hunk_id) ~= "string" or hunk_id == "" then
    return nil
  end
  if proposal_id and state.proposals[proposal_id] then
    for _, hunk in ipairs(state.proposals[proposal_id].hunks or {}) do
      if hunk.id == hunk_id then
        return hunk, state.proposals[proposal_id]
      end
    end
    return nil
  end
  for _, proposal in pairs(state.proposals) do
    for _, hunk in ipairs(proposal.hunks or {}) do
      if hunk.id == hunk_id then
        return hunk, proposal
      end
    end
  end
  return nil
end

local function find_file_record(proposal_id, file_id)
  local proposal = state.proposals[proposal_id]
  if not proposal then
    return nil
  end
  for _, file in ipairs(proposal.files or {}) do
    if file.id == file_id then
      return file, proposal
    end
  end
  return nil
end

local function current_thread_id()
  local ok_state, alma_state = pcall(require, "alma.state")
  if ok_state and alma_state.thread_for_buf then
    local thread = alma_state.thread_for_buf(0)
    if thread and thread.id then
      return thread.id
    end
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_thread_id = vim.b[bufnr].alma_thread_id
  if type(buffer_thread_id) == "string" and buffer_thread_id ~= "" then
    return buffer_thread_id
  end

  return nil
end

local function visible_buffers_for_workspace(workspace)
  local root = workspace and workspace.root
  local out = {}
  local seen = {}

  if type(root) ~= "string" or root == "" then
    return out
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local bufnr = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
        local path = normalize_path(vim.api.nvim_buf_get_name(bufnr))
        if path and path_is_under(root, path) and not seen[path] then
          seen[path] = true
          local cursor = vim.api.nvim_win_get_cursor(win)
          table.insert(out, {
            path = path,
            bufnr = bufnr,
            filetype = vim.bo[bufnr].filetype,
            modified = vim.bo[bufnr].modified,
            cursor = { cursor[1], cursor[2] },
            window_range = { vim.fn.line("w0", win), vim.fn.line("w$", win) },
          })
        end
      end
    end
  end

  table.sort(out, function(a, b)
    return a.path < b.path
  end)
  return out
end

local function should_scan_file(path)
  if path:find("/%.alma/", 1, false) then
    return false
  end
  local name = vim.fn.fnamemodify(path, ":t")
  if name == ".DS_Store" then
    return false
  end
  return true
end

local function scan_workspace_files(workspace)
  local root = workspace and workspace.root
  local files = {}

  if type(root) ~= "string" or root == "" or not file_exists(root) then
    return files
  end

  local count = 0
  local function scan(dir)
    if count >= MAX_SCANNED_FILES then
      return
    end
    local fs = uv.fs_scandir(dir)
    if not fs then
      return
    end
    while count < MAX_SCANNED_FILES do
      local name, kind = uv.fs_scandir_next(fs)
      if not name then
        break
      end
      local path = path_join(dir, name)
      if kind == "directory" then
        if name ~= ".alma" and name ~= ".git" then
          scan(path)
        end
      elseif kind == "file" and should_scan_file(path) then
        local stat = uv.fs_stat(path)
        if stat then
          count = count + 1
          files[path] = {
            path = path,
            size = stat.size or 0,
            mtime = stat.mtime and stat.mtime.sec or 0,
          }
        end
      end
    end
  end

  scan(root)
  return files
end

local function new_snapshot_id(thread_id)
  return "snap-" .. sanitize_segment(thread_id) .. "-" .. timestamp_stem()
end

local function capture_snapshot(thread_id, workspace)
  return {
    id = new_snapshot_id(thread_id),
    captured_at = now_iso(),
    files = scan_workspace_files(workspace),
    visible_buffers = visible_buffers_for_workspace(workspace),
  }
end

local function changed_files_since_snapshot(previous, current_files)
  local out = {}
  previous = previous or {}
  local previous_files = previous.files or {}

  for path, current in pairs(current_files or {}) do
    local before = previous_files[path]
    if not before then
      table.insert(out, {
        path = path,
        status = "added",
        size = current.size,
        mtime = current.mtime,
      })
    elseif before.size ~= current.size or before.mtime ~= current.mtime then
      table.insert(out, {
        path = path,
        status = "modified",
        size = current.size,
        mtime = current.mtime,
        previous_size = before.size,
        previous_mtime = before.mtime,
      })
    end
  end

  for path, before in pairs(previous_files) do
    if not current_files[path] then
      table.insert(out, {
        path = path,
        status = "deleted",
        previous_size = before.size,
        previous_mtime = before.mtime,
      })
    end
  end

  table.sort(out, function(a, b)
    return a.path < b.path
  end)
  return out
end

local function ensure_review_highlights()
  pcall(vim.api.nvim_set_hl, 0, "AlmaZkReviewAdd", { link = "DiffAdd", default = true })
  pcall(vim.api.nvim_set_hl, 0, "AlmaZkReviewDelete", { link = "DiffDelete", default = true })
  pcall(vim.api.nvim_set_hl, 0, "AlmaZkReviewChange", { link = "DiffChange", default = true })
  pcall(vim.api.nvim_set_hl, 0, "AlmaZkReviewStatus", { link = "Comment", default = true })
  pcall(vim.api.nvim_set_hl, 0, "AlmaZkReviewStale", { link = "WarningMsg", default = true })
  pcall(vim.fn.sign_define, "AlmaZkReviewHunk", {
    text = "A>",
    texthl = "AlmaZkReviewStatus",
  })
end

local function buffer_for_path(path, load)
  path = normalize_path(path)
  if not path then
    return nil
  end
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local name = normalize_path(vim.api.nvim_buf_get_name(bufnr))
      if name == path then
        if load and not vim.api.nvim_buf_is_loaded(bufnr) then
          pcall(vim.fn.bufload, bufnr)
        end
        return bufnr
      end
    end
  end
  if not load then
    return nil
  end
  local bufnr = vim.fn.bufadd(path)
  if bufnr ~= 0 then
    pcall(vim.fn.bufload, bufnr)
    return bufnr
  end
  return nil
end

local function hunk_start_index(hunk)
  local old_start = tonumber(hunk.old_start) or 1
  local old_count = tonumber(hunk.old_count) or 0
  if old_count == 0 then
    return math.max(0, old_start)
  end
  return math.max(0, old_start - 1)
end

local function hunk_anchor_index(hunk, bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count <= 0 then
    return 0
  end
  return math.min(hunk_start_index(hunk), math.max(0, line_count - 1))
end

local function hunk_matches_buffer(hunk, bufnr)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end
  local old_text = hunk.old_text or {}
  local start_index = hunk_start_index(hunk)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if start_index > line_count then
    return false
  end
  local current = vim.api.nvim_buf_get_lines(bufnr, start_index, start_index + #old_text, false)
  return tables_equal(current, old_text)
end

local function hunk_state_hl(state_name)
  if state_name == "approved" or state_name == "applied" then
    return "AlmaZkReviewAdd"
  elseif state_name == "rejected" then
    return "AlmaZkReviewDelete"
  elseif state_name == "commented" then
    return "AlmaZkReviewChange"
  elseif state_name == "stale" then
    return "AlmaZkReviewStale"
  end
  return "AlmaZkReviewStatus"
end

local function hunk_virtual_lines(hunk)
  local state_name = hunk.state or "pending"
  local lines = {
    {
      { hunk.header .. " [" .. state_name .. "]", hunk_state_hl(state_name) },
    },
  }

  if hunk.kind == "replacement" then
    table.insert(lines, {
      { "~ replacement", "AlmaZkReviewChange" },
    })
  end

  for _, text in ipairs(hunk.removed_lines or {}) do
    table.insert(lines, {
      { "- " .. text, "AlmaZkReviewDelete" },
    })
  end
  for _, text in ipairs(hunk.added_lines or {}) do
    table.insert(lines, {
      { "+ " .. text, "AlmaZkReviewAdd" },
    })
  end
  if type(hunk.comment) == "string" and hunk.comment ~= "" then
    table.insert(lines, {
      { "comment: " .. hunk.comment, "AlmaZkReviewChange" },
    })
  end

  return lines
end

local function mark_buffer_review_keymaps(bufnr)
  if vim.b[bufnr].alma_zk_review_keymaps then
    return
  end
  vim.b[bufnr].alma_zk_review_keymaps = true
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "]h", function()
    require("util.alma_zk_blackboard").next_hunk()
  end, vim.tbl_extend("force", opts, { desc = "Next Alma review hunk" }))
  vim.keymap.set("n", "[h", function()
    require("util.alma_zk_blackboard").previous_hunk()
  end, vim.tbl_extend("force", opts, { desc = "Previous Alma review hunk" }))
  vim.keymap.set("n", "<leader>ha", function()
    require("util.alma_zk_blackboard").approve_current_hunk()
  end, vim.tbl_extend("force", opts, { desc = "Approve Alma review hunk" }))
  vim.keymap.set("n", "<leader>hr", function()
    require("util.alma_zk_blackboard").reject_current_hunk()
  end, vim.tbl_extend("force", opts, { desc = "Reject Alma review hunk" }))
  vim.keymap.set("n", "<leader>hc", function()
    require("util.alma_zk_blackboard").comment_current_hunk()
  end, vim.tbl_extend("force", opts, { desc = "Comment Alma review hunk" }))
  vim.keymap.set("n", "<leader>hf", function()
    require("util.alma_zk_blackboard").approve_current_file()
  end, vim.tbl_extend("force", opts, { desc = "Approve Alma review file" }))
  vim.keymap.set("n", "<leader>hR", function()
    require("util.alma_zk_blackboard").reject_current_file()
  end, vim.tbl_extend("force", opts, { desc = "Reject Alma review file" }))
  vim.keymap.set("n", "<leader>hp", function()
    require("util.alma_zk_blackboard").open_review_picker()
  end, vim.tbl_extend("force", opts, { desc = "Open Alma review picker" }))
  vim.keymap.set("n", "<leader>hA", function()
    require("util.alma_zk_blackboard").apply_approved()
  end, vim.tbl_extend("force", opts, { desc = "Apply approved Alma hunks" }))
end

local function render_file_review(file, opts)
  opts = opts or {}
  if type(file) ~= "table" or type(file.path) ~= "string" then
    return nil
  end
  local bufnr = buffer_for_path(file.path, true)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  ensure_review_highlights()
  if not opts.keep_existing then
    vim.api.nvim_buf_clear_namespace(bufnr, REVIEW_NAMESPACE, 0, -1)
  end
  mark_buffer_review_keymaps(bufnr)

  for _, hunk in ipairs(file.hunks or {}) do
    if hunk.state ~= "applied" then
      if not hunk_matches_buffer(hunk, bufnr) then
        hunk.state = "stale"
      end

      local anchor = hunk_anchor_index(hunk, bufnr)
      hunk.anchor_line = anchor + 1
      local opts = {
        virt_text = { { "[alma " .. hunk.id .. " " .. hunk.state .. "]", hunk_state_hl(hunk.state) } },
        virt_text_pos = "eol",
        virt_lines = hunk_virtual_lines(hunk),
        virt_lines_above = false,
        hl_mode = "combine",
        sign_text = "A>",
        sign_hl_group = hunk_state_hl(hunk.state),
      }
      local ok = pcall(vim.api.nvim_buf_set_extmark, bufnr, REVIEW_NAMESPACE, anchor, 0, opts)
      if not ok then
        opts.sign_text = nil
        opts.sign_hl_group = nil
        pcall(vim.api.nvim_buf_set_extmark, bufnr, REVIEW_NAMESPACE, anchor, 0, opts)
      end
    end
  end

  return bufnr
end

local function render_proposal_review(proposal)
  if type(proposal) ~= "table" then
    return
  end
  for _, file in ipairs(proposal.files or {}) do
    render_file_review(file)
  end
end

local function render_all_reviews_for_path(path)
  path = normalize_path(path)
  if not path then
    return
  end
  local bufnr = buffer_for_path(path, true)
  if bufnr then
    vim.api.nvim_buf_clear_namespace(bufnr, REVIEW_NAMESPACE, 0, -1)
  end
  for _, proposal in pairs(state.proposals) do
    for _, file in ipairs(proposal.files or {}) do
      if normalize_path(file.path) == path then
        render_file_review(file, { keep_existing = true })
      end
    end
  end
end

local function default_review_feedback()
  return {
    proposal_id = nil,
    summary = {
      approved = 0,
      rejected = 0,
      commented = 0,
      pending = 0,
      stale = 0,
      applied = 0,
    },
    comments = {},
    rejected_hunks = {},
    proposals = {},
  }
end

local function merge_summary(target, source)
  for key, value in pairs(source or {}) do
    if type(value) == "number" then
      target[key] = (target[key] or 0) + value
    end
  end
end

local function proposal_feedback_for_thread(thread_id)
  local feedback = default_review_feedback()
  local proposal_ids = vim.tbl_keys(state.proposals)
  table.sort(proposal_ids)

  for _, proposal_id in ipairs(proposal_ids) do
    local proposal = state.proposals[proposal_id]
    if proposal.thread_id == thread_id then
      local proposal_summary = {
        approved = 0,
        rejected = 0,
        commented = 0,
        pending = 0,
        stale = 0,
        applied = 0,
      }

      for _, hunk in ipairs(proposal.hunks or {}) do
        local state_name = hunk.state or "pending"
        proposal_summary[state_name] = (proposal_summary[state_name] or 0) + 1
        if state_name == "commented" then
          table.insert(feedback.comments, {
            proposal_id = proposal.id,
            file_id = hunk.file_id,
            hunk_id = hunk.id,
            path = hunk.path,
            relative_path = hunk.relative_path,
            old_start = hunk.old_start,
            new_start = hunk.new_start,
            comment = hunk.comment or "",
            diff = hunk_diff_text(hunk),
          })
        elseif state_name == "rejected" then
          table.insert(feedback.rejected_hunks, {
            proposal_id = proposal.id,
            file_id = hunk.file_id,
            hunk_id = hunk.id,
            path = hunk.path,
            relative_path = hunk.relative_path,
            old_start = hunk.old_start,
            new_start = hunk.new_start,
            reason = hunk.comment or "",
            diff = hunk_diff_text(hunk),
          })
        end
      end

      merge_summary(feedback.summary, proposal_summary)
      feedback.proposal_id = feedback.proposal_id or proposal.id
      table.insert(feedback.proposals, {
        proposal_id = proposal.id,
        title = proposal.title,
        state = proposal.state,
        summary = proposal_summary,
      })
    end
  end

  return feedback
end

local function feedback_has_content(feedback)
  if type(feedback) ~= "table" then
    return false
  end
  if type(feedback.proposal_id) == "string" and feedback.proposal_id ~= "" then
    return true
  end
  return table_count(feedback.comments) > 0
    or table_count(feedback.rejected_hunks) > 0
    or table_count(feedback.proposals) > 0
end

local function refresh_review_feedback(thread_id)
  if type(thread_id) ~= "string" or thread_id == "" then
    return
  end
  local feedback = proposal_feedback_for_thread(thread_id)
  if feedback_has_content(feedback) then
    feedback._generated = true
    state.review_feedback[thread_id] = feedback
  else
    state.review_feedback[thread_id] = nil
  end
end

local function review_feedback(thread_id)
  local generated = proposal_feedback_for_thread(thread_id)
  local feedback = state.review_feedback[thread_id]
  if type(feedback) ~= "table" then
    return generated
  end
  if feedback._generated then
    return generated
  end
  if not feedback_has_content(generated) then
    return vim.tbl_deep_extend("force", default_review_feedback(), vim.deepcopy(feedback))
  end

  local merged = vim.tbl_deep_extend("force", generated, vim.deepcopy(feedback))
  merged.comments = vim.deepcopy(generated.comments or {})
  vim.list_extend(merged.comments, feedback.comments or {})
  merged.rejected_hunks = vim.deepcopy(generated.rejected_hunks or {})
  vim.list_extend(merged.rejected_hunks, feedback.rejected_hunks or {})
  merged.proposals = vim.deepcopy(generated.proposals or {})
  vim.list_extend(merged.proposals, feedback.proposals or {})
  return merged
end

local function workspace_facts(workspace)
  local facts = vim.deepcopy(workspace)
  facts.source = facts.source or "unknown"
  return facts
end

local function build_attachment_payload(thread_id, workspace, binding)
  local previous_snapshot = state.snapshots[thread_id]
  local current_files = scan_workspace_files(workspace)
  local visible_buffers = visible_buffers_for_workspace(workspace)
  local snapshot_id = new_snapshot_id(thread_id)
  local sync_key = table.concat({ thread_id, workspace.id, vim.v.servername or "nvim" }, ":")
  local first_rpc_sync = state.rpc_sync[sync_key] ~= true

  return {
    kind = "alma.nvim.zk_blackboard_context",
    version = 1,
    generated_at = now_iso(),
    thread_id = thread_id,
    workspace = workspace_facts(workspace),
    blackboard = {
      mode = binding.mode or "blackboard",
      workspace_id = workspace.id,
      binding_created_at = binding.created_at,
      snapshot_id = snapshot_id,
      previous_snapshot_id = previous_snapshot and previous_snapshot.id or nil,
      rpc_previously_synced = not first_rpc_sync,
      rpc_sync_required = first_rpc_sync,
      nvim_servername = vim.v.servername ~= "" and vim.v.servername or nil,
      rpc = {
        servername = vim.v.servername ~= "" and vim.v.servername or nil,
        sync_key = sync_key,
        sync_required = first_rpc_sync,
        capabilities = {
          neovim_rpc = vim.v.servername ~= "",
          inline_review_overlay = true,
          structured_review_feedback = true,
          file_backed_context_attachment = true,
        },
      },
    },
    visible_buffers = visible_buffers,
    changed_files_since_snapshot = changed_files_since_snapshot(previous_snapshot, current_files),
    review_feedback = review_feedback(thread_id),
  },
    {
      id = snapshot_id,
      files = current_files,
      visible_buffers = visible_buffers,
      rpc_sync_key = sync_key,
    }
end

local function attachment_dir(workspace, thread_id)
  return path_join(workspace.root, ".alma", "attachments", sanitize_segment(thread_id))
end

local function write_attachment_json(workspace, thread_id, payload)
  local dir = attachment_dir(workspace, thread_id)
  local ok_mkdir, mkdir_err = pcall(vim.fn.mkdir, dir, "p")
  if not ok_mkdir then
    return nil, "failed to create attachment directory: " .. tostring(mkdir_err)
  end

  local path = path_join(dir, timestamp_stem() .. ".blackboard-context.json")
  local ok_encode, encoded = pcall(vim.json.encode, payload)
  if not ok_encode then
    return nil, "failed to encode attachment JSON: " .. tostring(encoded)
  end

  local ok_write, write_result = pcall(vim.fn.writefile, { encoded }, path, "b")
  if not ok_write or write_result ~= 0 then
    return nil, "failed to write attachment JSON: " .. tostring(ok_write and write_result or write_result)
  end

  return path
end

local function ensure_spec_metadata(spec, attachment)
  if type(spec) ~= "table" then
    return
  end
  spec.metadata = type(spec.metadata) == "table" and spec.metadata or {}
  local metadata = spec.metadata
  metadata.attachments = type(metadata.attachments) == "table" and metadata.attachments or {}
  table.insert(metadata.attachments, attachment)
  metadata.attachment_count = #metadata.attachments
  metadata.attachmentCount = #metadata.attachments
  metadata.attachment_labels = type(metadata.attachment_labels) == "table" and metadata.attachment_labels or {}
  metadata.attachmentLabels = type(metadata.attachmentLabels) == "table" and metadata.attachmentLabels or metadata.attachment_labels
  table.insert(metadata.attachment_labels, attachment.label)
  metadata.attachmentLabels = metadata.attachment_labels
end

local function append_ephemeral_context(spec, path, attachment_id)
  if type(spec) ~= "table" then
    return false
  end

  spec.ephemeral_context = type(spec.ephemeral_context) == "table" and spec.ephemeral_context or {}
  table.insert(spec.ephemeral_context, {
    type = "file",
    id = attachment_id,
    title = "ZK Blackboard Context",
    label = "ZK Blackboard Context",
    path = path,
    mediaType = "application/json",
    metadata = {
      attachmentType = "json",
      fileBacked = true,
      source = "zk-alma-blackboard-fallback",
    },
  })
  ensure_spec_metadata(spec, {
    id = attachment_id,
    type = "json",
    label = "ZK Blackboard Context",
    mediaType = "application/json",
    filename = vim.fn.fnamemodify(path, ":t"),
    fileBacked = true,
  })
  return true
end

local function attach_context(event, thread_id, path, snapshot_id)
  local attachment_id = "zk-blackboard:" .. snapshot_id
  local ok_context, context = pcall(require, "alma.context")
  if ok_context and type(context) == "table" and type(context.attach) == "function" then
    local ok_attach = pcall(context.attach, thread_id, {
      type = "json",
      id = attachment_id,
      title = "ZK Blackboard Context",
      label = "ZK Blackboard Context",
      path = path,
      inline = false,
      once = true,
      mediaType = "application/json",
      metadata = {
        source = "zk-alma-blackboard",
        snapshot_id = snapshot_id,
        fileBacked = true,
      },
    })
    if ok_attach then
      return "alma.context"
    end
  end

  if append_ephemeral_context(event and event.spec, path, attachment_id) then
    return "ephemeralContext"
  end

  return nil
end

local function normalize_proposal_record(event)
  event = type(event) == "table" and event or {}
  local proposal = event.proposal or event
  if type(proposal) ~= "table" then
    return nil, "proposal payload must be a table"
  end

  local thread_id = event.thread_id
    or proposal.thread_id
    or proposal.threadId
    or proposal.parent_thread_id
    or proposal.parentThreadId
    or current_thread_id()
  local workspace = proposal_workspace(thread_id)
  local proposal_id = proposal_id_from_payload(proposal)
  local record = {
    id = proposal_id,
    thread_id = thread_id,
    title = proposal.title or proposal.name or proposal.summary or ("Proposal " .. proposal_id),
    kind = proposal.kind or proposal.format or "diff",
    base_snapshot_id = proposal.base_snapshot_id
      or proposal.baseSnapshotId
      or proposal.base_id
      or proposal.baseId
      or proposal.snapshot_id
      or proposal.snapshotId,
    created_at = now_iso(),
    state = "reviewing",
    workspace_id = workspace and workspace.id or nil,
    files = {},
    hunks = {},
    raw = proposal,
  }

  for file_index, file in ipairs(proposal_files_from_payload(proposal)) do
    if type(file) == "table" then
      local diff = file.diff or file.patch or file.unified_diff or file.unifiedDiff
      local normalized_file = vim.deepcopy(file)
      normalized_file.diff = diff
      local path, relative_path = proposal_file_path(normalized_file, workspace)
      if workspace and path and not path_is_under(workspace.root, path) then
        path = nil
      end
      if path and type(diff) == "string" and diff ~= "" then
        local file_id = proposal_id .. ":f" .. tostring(file_index)
        local file_record = {
          id = file_id,
          proposal_id = proposal_id,
          index = file_index,
          path = path,
          relative_path = relative_path or path,
          diff = diff,
          hunks = {},
          raw = file,
        }

        for hunk_index, hunk in ipairs(parse_unified_diff(diff)) do
          local hunk_id = proposal_id .. ":h" .. tostring(#record.hunks + 1)
          hunk.id = hunk_id
          hunk.proposal_id = proposal_id
          hunk.file_id = file_id
          hunk.index = hunk_index
          hunk.path = path
          hunk.relative_path = file_record.relative_path
          hunk.state = "pending"
          hunk.anchor_line = hunk.old_start
          table.insert(file_record.hunks, hunk)
          table.insert(record.hunks, hunk)
        end

        table.insert(record.files, file_record)
      end
    end
  end

  if #record.files == 0 then
    return nil, "proposal did not contain any usable file diffs"
  end
  if #record.hunks == 0 then
    return nil, "proposal did not contain any unified diff hunks"
  end

  return record
end

local function set_hunk_review_state(hunk, state_name, comment)
  if type(hunk) ~= "table" then
    return nil, "hunk not found"
  end
  if not REVIEW_STATES[state_name] then
    return nil, "invalid hunk state: " .. tostring(state_name)
  end
  if hunk.state == "stale" and state_name ~= "stale" then
    return nil, "hunk is stale; request a revised proposal before review"
  end
  if hunk.state == "applied" and state_name ~= "applied" then
    return nil, "hunk has already been applied"
  end

  hunk.state = state_name
  if state_name == "commented" or (type(comment) == "string" and comment ~= "") then
    hunk.comment = comment or hunk.comment or ""
  elseif state_name == "approved" then
    hunk.comment = nil
  end

  local file = find_file_record(hunk.proposal_id, hunk.file_id)
  if file then
    render_all_reviews_for_path(file.path)
  end
  local proposal = state.proposals[hunk.proposal_id]
  if proposal and proposal.thread_id then
    refresh_review_feedback(proposal.thread_id)
  end
  return hunk
end

local function current_buffer_review_hunks()
  local path = normalize_path(vim.api.nvim_buf_get_name(0))
  local hunks = {}
  if not path then
    return hunks
  end
  for _, hunk in ipairs(all_proposal_hunks()) do
    if normalize_path(hunk.path) == path then
      table.insert(hunks, hunk)
    end
  end
  return hunks
end

local function current_hunk()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local hunks = current_buffer_review_hunks()
  local nearest
  for _, hunk in ipairs(hunks) do
    local start_line = hunk.anchor_line or hunk.old_start or 1
    local end_line = start_line + math.max((hunk.old_count or 1) - 1, 0)
    if cursor_line >= start_line and cursor_line <= end_line then
      return hunk
    end
    if start_line <= cursor_line then
      nearest = hunk
    end
  end
  return nearest or hunks[1]
end

local function set_current_hunk_state(state_name, comment)
  local hunk = current_hunk()
  if not hunk then
    notify("No Alma review hunk in the current buffer", vim.log.levels.WARN)
    return nil
  end
  local updated, err = set_hunk_review_state(hunk, state_name, comment)
  if not updated then
    notify(err, vim.log.levels.WARN)
    return nil
  end
  notify("Marked " .. hunk.id .. " " .. state_name)
  return updated
end

local function set_file_hunks_state(path, state_name)
  path = normalize_path(path or vim.api.nvim_buf_get_name(0))
  if not path then
    notify("No file path for current buffer", vim.log.levels.WARN)
    return 0
  end
  local count = 0
  for _, hunk in ipairs(all_proposal_hunks()) do
    if normalize_path(hunk.path) == path and hunk.state ~= "stale" and hunk.state ~= "applied" then
      local ok = set_hunk_review_state(hunk, state_name)
      if ok then
        count = count + 1
      end
    end
  end
  notify("Marked " .. tostring(count) .. " hunks " .. state_name)
  return count
end

local function proposal_gate(proposal_id)
  local proposal = proposal_id and state.proposals[proposal_id] or nil
  if not proposal then
    local ids = vim.tbl_keys(state.proposals)
    table.sort(ids)
    proposal = state.proposals[ids[1]]
  end
  if not proposal then
    return nil, "no proposal is available"
  end

  for _, file in ipairs(proposal.files or {}) do
    local bufnr = buffer_for_path(file.path, true)
    if bufnr then
      for _, hunk in ipairs(file.hunks or {}) do
        if hunk.state ~= "applied" and not hunk_matches_buffer(hunk, bufnr) then
          hunk.state = "stale"
        end
      end
      render_all_reviews_for_path(file.path)
    end
  end

  local blockers = {}
  local approved = {}
  for _, hunk in ipairs(proposal.hunks or {}) do
    local state_name = hunk.state or "pending"
    if state_name == "pending" or state_name == "commented" or state_name == "stale" then
      table.insert(blockers, {
        hunk_id = hunk.id,
        file_id = hunk.file_id,
        path = hunk.path,
        state = state_name,
      })
    elseif state_name == "approved" then
      table.insert(approved, hunk)
    end
  end

  return {
    ok = #blockers == 0,
    proposal_id = proposal.id,
    blockers = blockers,
    approved_hunks = approved,
  }
end

local function apply_hunk_to_buffer(hunk, bufnr)
  if not hunk_matches_buffer(hunk, bufnr) then
    hunk.state = "stale"
    return nil, "hunk is stale: " .. hunk.id
  end
  local start_index = hunk_start_index(hunk)
  local old_text = hunk.old_text or {}
  local new_text = hunk.new_text or {}
  vim.api.nvim_buf_set_lines(bufnr, start_index, start_index + #old_text, false, new_text)
  hunk.state = "applied"
  return true
end

local function apply_approved_hunks(proposal_id)
  local gate, err = proposal_gate(proposal_id)
  if not gate then
    return nil, err
  end
  if not gate.ok then
    return nil, "cannot apply while hunks are pending, commented, or stale"
  end

  local by_file = {}
  for _, hunk in ipairs(gate.approved_hunks) do
    by_file[hunk.file_id] = by_file[hunk.file_id] or {}
    table.insert(by_file[hunk.file_id], hunk)
  end

  local applied = 0
  for file_id, hunks in pairs(by_file) do
    local file = find_file_record(gate.proposal_id, file_id)
    if not file then
      return nil, "file record not found: " .. tostring(file_id)
    end
    local bufnr = buffer_for_path(file.path, true)
    if not bufnr then
      return nil, "could not load target buffer: " .. tostring(file.path)
    end
    table.sort(hunks, function(a, b)
      return hunk_start_index(a) > hunk_start_index(b)
    end)
    for _, hunk in ipairs(hunks) do
      local ok, apply_err = apply_hunk_to_buffer(hunk, bufnr)
      if not ok then
        render_all_reviews_for_path(file.path)
        return nil, apply_err
      end
      applied = applied + 1
    end
    render_all_reviews_for_path(file.path)
  end

  local proposal = state.proposals[gate.proposal_id]
  if proposal then
    proposal.state = "applied"
    refresh_review_feedback(proposal.thread_id)
  end

  return {
    proposal_id = gate.proposal_id,
    applied = applied,
  }
end

local function make_status_lines()
  local lines = {}
  table.insert(lines, "ZK Alma Blackboard")
  table.insert(lines, "current workspace: " .. tostring(state.current_workspace_id or "none"))

  local workspace_ids = vim.tbl_keys(state.workspaces)
  table.sort(workspace_ids)
  table.insert(lines, "registered workspaces: " .. (#workspace_ids > 0 and table.concat(workspace_ids, ", ") or "none"))

  local binding_ids = vim.tbl_keys(state.thread_bindings)
  table.sort(binding_ids)
  if #binding_ids == 0 then
    table.insert(lines, "thread bindings: none")
  else
    table.insert(lines, "thread bindings:")
    for _, thread_id in ipairs(binding_ids) do
      local binding = state.thread_bindings[thread_id]
      table.insert(lines, string.format("  %s -> %s (%s)", thread_id, binding.workspace_id, binding.mode or "blackboard"))
    end
  end

  local proposal_ids = vim.tbl_keys(state.proposals)
  table.sort(proposal_ids)
  if #proposal_ids == 0 then
    table.insert(lines, "review proposals: none")
  else
    table.insert(lines, "review proposals:")
    for _, proposal_id in ipairs(proposal_ids) do
      local proposal = state.proposals[proposal_id]
      local feedback = proposal_feedback_for_thread(proposal.thread_id)
      table.insert(
        lines,
        string.format(
          "  %s: %d files, %d hunks, %d pending, %d commented, %d rejected, %d stale",
          proposal_id,
          #proposal.files,
          #proposal.hunks,
          feedback.summary.pending or 0,
          feedback.summary.commented or 0,
          feedback.summary.rejected or 0,
          feedback.summary.stale or 0
        )
      )
    end
  end

  local last_ids = vim.tbl_keys(state.last_attachment)
  table.sort(last_ids)
  if #last_ids > 0 then
    table.insert(lines, "last attachments:")
    for _, thread_id in ipairs(last_ids) do
      table.insert(lines, "  " .. thread_id .. ": " .. tostring(state.last_attachment[thread_id]))
    end
  end

  return lines
end

local function command_workspace_register(opts)
  local arg = opts.args ~= "" and opts.args or nil
  local workspace_id = arg

  if not workspace_id then
    workspace_id = detect_workspace_id(vim.api.nvim_buf_get_name(0)) or detect_workspace_id(current_dir())
  elseif workspace_id:find("/", 1, true) then
    workspace_id = detect_workspace_id(workspace_id) or vim.fn.fnamemodify(workspace_id, ":t")
  end

  if type(workspace_id) ~= "string" or workspace_id == "" then
    notify("No workspace id found for registration", vim.log.levels.WARN)
    return
  end

  local workspace, err = describe_workspace(workspace_id)
  if not workspace then
    notify(err or ("Unable to register workspace " .. workspace_id), vim.log.levels.WARN)
    return
  end

  state.workspaces[workspace.id] = workspace
  state.current_workspace_id = workspace.id
  notify("Registered workspace " .. workspace.id)
end

local function bind_thread(thread_id, workspace_id)
  if type(thread_id) ~= "string" or thread_id == "" then
    return nil, "thread id is required"
  end

  workspace_id = workspace_id or state.current_workspace_id or detect_workspace_id(vim.api.nvim_buf_get_name(0)) or detect_workspace_id(current_dir())
  if type(workspace_id) ~= "string" or workspace_id == "" then
    return nil, "workspace id is required"
  end

  local workspace = workspace_for_id(workspace_id)
  if not workspace then
    return nil, "workspace is not registered and could not be described: " .. workspace_id
  end

  state.workspaces[workspace.id] = workspace
  state.current_workspace_id = workspace.id
  state.thread_bindings[thread_id] = {
    workspace_id = workspace.id,
    mode = "blackboard",
    created_at = now_iso(),
  }
  state.snapshots[thread_id] = capture_snapshot(thread_id, workspace)
  return state.thread_bindings[thread_id]
end

local function command_blackboard_bind(opts)
  local args = opts.fargs or {}
  local thread_id = current_thread_id()
  local workspace_id = state.current_workspace_id

  if #args == 1 then
    if thread_id then
      workspace_id = args[1]
    else
      thread_id = args[1]
    end
  elseif #args >= 2 then
    thread_id = args[1]
    workspace_id = args[2]
  end

  local binding, err = bind_thread(thread_id, workspace_id)
  if not binding then
    notify(err, vim.log.levels.WARN)
    return
  end

  notify("Bound thread " .. thread_id .. " to workspace " .. binding.workspace_id)
end

local function command_blackboard_unbind(opts)
  local thread_id = opts.args ~= "" and opts.args or current_thread_id()
  if type(thread_id) ~= "string" or thread_id == "" then
    notify("thread id is required", vim.log.levels.WARN)
    return
  end

  state.thread_bindings[thread_id] = nil
  state.snapshots[thread_id] = nil
  state.review_feedback[thread_id] = nil
  state.last_attachment[thread_id] = nil
  notify("Unbound thread " .. thread_id)
end

local function command_status()
  local lines = make_status_lines()
  if vim.ui and vim.ui.select then
    vim.notify(table.concat(lines, "\n"))
  else
    print(table.concat(lines, "\n"))
  end
end

local function command_review_approve(opts)
  local hunk_id = opts.args ~= "" and opts.args or nil
  local hunk = hunk_id and find_hunk(hunk_id) or current_hunk()
  local updated, err = set_hunk_review_state(hunk, "approved")
  if not updated then
    notify(err or "No hunk selected", vim.log.levels.WARN)
    return
  end
  notify("Approved " .. updated.id)
end

local function command_review_reject(opts)
  local hunk_id = opts.args ~= "" and opts.args or nil
  local hunk = hunk_id and find_hunk(hunk_id) or current_hunk()
  local updated, err = set_hunk_review_state(hunk, "rejected")
  if not updated then
    notify(err or "No hunk selected", vim.log.levels.WARN)
    return
  end
  notify("Rejected " .. updated.id)
end

local function command_review_comment(opts)
  local args = opts.fargs or {}
  local hunk
  local comment = opts.args
  if #args > 0 then
    hunk = find_hunk(args[1])
    if hunk then
      table.remove(args, 1)
      comment = table.concat(args, " ")
    end
  end
  hunk = hunk or current_hunk()
  if not hunk then
    notify("No hunk selected", vim.log.levels.WARN)
    return
  end
  if comment == "" and vim.ui and vim.ui.input then
    vim.ui.input({ prompt = "Alma hunk comment: " }, function(input)
      if input ~= nil then
        local updated, err = set_hunk_review_state(hunk, "commented", input)
        if not updated then
          notify(err, vim.log.levels.WARN)
        end
      end
    end)
    return
  end
  local updated, err = set_hunk_review_state(hunk, "commented", comment)
  if not updated then
    notify(err, vim.log.levels.WARN)
    return
  end
  notify("Commented " .. updated.id)
end

local function command_review_apply(opts)
  local proposal_id = opts.args ~= "" and opts.args or nil
  local result, err = apply_approved_hunks(proposal_id)
  if not result then
    notify(err, vim.log.levels.WARN)
    return
  end
  notify("Applied " .. tostring(result.applied) .. " approved hunks from " .. result.proposal_id)
end

local function command_review_gate(opts)
  local proposal_id = opts.args ~= "" and opts.args or nil
  local gate, err = proposal_gate(proposal_id)
  if not gate then
    notify(err, vim.log.levels.WARN)
    return
  end
  if gate.ok then
    notify("Review gate open for " .. gate.proposal_id .. "; approved hunks: " .. tostring(#gate.approved_hunks))
    return
  end
  local lines = { "Review gate blocked for " .. gate.proposal_id .. ":" }
  for _, blocker in ipairs(gate.blockers) do
    table.insert(lines, "  " .. blocker.hunk_id .. " " .. blocker.state .. " " .. blocker.path)
  end
  notify(table.concat(lines, "\n"), vim.log.levels.WARN)
end

local function command_review_clear(opts)
  local proposal_id = opts.args ~= "" and opts.args or nil
  local ids = proposal_id and { proposal_id } or vim.tbl_keys(state.proposals)
  for _, id in ipairs(ids) do
    local proposal = state.proposals[id]
    if proposal then
      for _, file in ipairs(proposal.files or {}) do
        local bufnr = buffer_for_path(file.path, false)
        if bufnr then
          vim.api.nvim_buf_clear_namespace(bufnr, REVIEW_NAMESPACE, 0, -1)
        end
      end
      if proposal.thread_id then
        state.review_feedback[proposal.thread_id] = nil
      end
      state.proposals[id] = nil
    end
  end
  notify("Cleared Alma review overlays")
end

local function command_review_list()
  local lines = { "Alma review hunks:" }
  for _, hunk in ipairs(all_proposal_hunks()) do
    table.insert(
      lines,
      string.format(
        "  %s %s %s:%s %s",
        hunk.id,
        hunk.state or "pending",
        hunk.relative_path or hunk.path,
        hunk.anchor_line or hunk.old_start,
        hunk.header
      )
    )
  end
  if #lines == 1 then
    table.insert(lines, "  none")
  end
  notify(table.concat(lines, "\n"))
end

local function command_review_goto(opts)
  local args = opts.fargs or {}
  local hunk_id = args[#args]
  if not hunk_id then
    notify("Usage: ZkAlmaReviewGoto [proposal-id] <hunk-id>", vim.log.levels.WARN)
    return
  end
  local ok, err = M.goto_hunk(hunk_id, args[1] ~= hunk_id and args[1] or nil)
  if not ok then
    notify(err, vim.log.levels.WARN)
  end
end

local function command_review_picker()
  M.open_review_picker()
end

local on_after_submit
local on_proposal_received

local function on_before_submit(event)
  event = event or {}
  if event._zk_alma_blackboard_attached then
    return
  end

  local thread_id = event.thread_id or (event.thread and event.thread.id)
  if type(thread_id) ~= "string" or thread_id == "" then
    return
  end

  local binding = state.thread_bindings[thread_id]
  if type(binding) ~= "table" then
    return
  end

  local workspace = workspace_for_id(binding.workspace_id)
  if not workspace then
    notify("Bound workspace is unavailable: " .. tostring(binding.workspace_id), vim.log.levels.WARN)
    return
  end

  local payload, pending_snapshot = build_attachment_payload(thread_id, workspace, binding)
  local path, write_err = write_attachment_json(workspace, thread_id, payload)
  if not path then
    notify(write_err, vim.log.levels.ERROR)
    return
  end

  local attach_method = attach_context(event, thread_id, path, pending_snapshot.id)
  if not attach_method then
    notify("Wrote blackboard JSON but could not attach it to the request: " .. path, vim.log.levels.WARN)
    return
  end

  event._zk_alma_blackboard_attached = true
  pending_snapshot.path = path
  pending_snapshot.attached_by = attach_method
  state.snapshots[thread_id] = pending_snapshot
  if pending_snapshot.rpc_sync_key then
    state.rpc_sync[pending_snapshot.rpc_sync_key] = true
  end
  state.last_attachment[thread_id] = path
end

local function try_register_hooks()
  if state.hooks_registered then
    return
  end

  local ok_hooks, hooks = pcall(require, "alma.hooks")
  if not ok_hooks or type(hooks) ~= "table" or type(hooks.on) ~= "function" then
    return
  end

  hooks.on("before_submit", on_before_submit)
  hooks.on("after_submit", on_after_submit)
  hooks.on("proposal_received", on_proposal_received)
  state.hooks_registered = true
end

on_after_submit = function(event)
  event = event or {}
  local thread_id = event.thread_id or (event.thread and event.thread.id)
  if type(thread_id) == "string" and state.review_feedback[thread_id] then
    state.review_feedback[thread_id] = nil
  end
end

on_proposal_received = function(event)
  local proposal, err = normalize_proposal_record(event)
  if not proposal then
    notify("Ignored proposal: " .. tostring(err), vim.log.levels.WARN)
    return
  end
  state.proposals[proposal.id] = proposal
  render_proposal_review(proposal)
  refresh_review_feedback(proposal.thread_id)
  notify(
    string.format(
      "Received proposal %s (%d files, %d hunks)",
      proposal.id,
      #proposal.files,
      #proposal.hunks
    )
  )
end

local function complete_workspaces(arg_lead)
  local matches = {}
  local seen = {}
  for _, id in ipairs(list_workspace_ids()) do
    if id:find(arg_lead, 1, true) == 1 and not seen[id] then
      seen[id] = true
      table.insert(matches, id)
    end
  end
  table.sort(matches)
  return matches
end

function M.register_workspace(id)
  local workspace, err = describe_workspace(id)
  if workspace then
    state.workspaces[workspace.id] = workspace
    state.current_workspace_id = workspace.id
  end
  return workspace, err
end

function M.bind(thread_id, workspace_id)
  return bind_thread(thread_id, workspace_id)
end

function M.unbind(thread_id)
  state.thread_bindings[thread_id] = nil
  state.snapshots[thread_id] = nil
end

function M.status()
  local review_feedback_state = vim.deepcopy(state.review_feedback)
  for _, feedback in pairs(review_feedback_state) do
    if type(feedback) == "table" then
      feedback._generated = nil
    end
  end
  return {
    current_workspace_id = state.current_workspace_id,
    workspaces = vim.deepcopy(state.workspaces),
    thread_bindings = vim.deepcopy(state.thread_bindings),
    snapshots = vim.deepcopy(state.snapshots),
    proposals = vim.deepcopy(state.proposals),
    review_feedback = review_feedback_state,
    last_attachment = vim.deepcopy(state.last_attachment),
  }
end

function M.set_review_feedback(thread_id, feedback)
  if type(thread_id) == "string" and thread_id ~= "" then
    state.review_feedback[thread_id] = vim.deepcopy(feedback or default_review_feedback())
  end
end

function M.ingest_proposal(event)
  local proposal, err = normalize_proposal_record(event)
  if not proposal then
    return nil, err
  end
  state.proposals[proposal.id] = proposal
  render_proposal_review(proposal)
  refresh_review_feedback(proposal.thread_id)
  return proposal
end

function M.review_gate(proposal_id)
  return proposal_gate(proposal_id)
end

function M.apply_approved(proposal_id)
  local result, err = apply_approved_hunks(proposal_id)
  if not result then
    notify(err, vim.log.levels.WARN)
    return nil, err
  end
  notify("Applied " .. tostring(result.applied) .. " approved hunks from " .. result.proposal_id)
  return result
end

function M.approve_hunk(hunk_id, proposal_id)
  local hunk = find_hunk(hunk_id, proposal_id)
  return set_hunk_review_state(hunk, "approved")
end

function M.reject_hunk(hunk_id, proposal_id)
  local hunk = find_hunk(hunk_id, proposal_id)
  return set_hunk_review_state(hunk, "rejected")
end

function M.comment_hunk(hunk_id, comment, proposal_id)
  local hunk = find_hunk(hunk_id, proposal_id)
  return set_hunk_review_state(hunk, "commented", comment or "")
end

function M.approve_current_hunk()
  return set_current_hunk_state("approved")
end

function M.reject_current_hunk()
  return set_current_hunk_state("rejected")
end

function M.comment_current_hunk(comment)
  if type(comment) == "string" then
    return set_current_hunk_state("commented", comment)
  end
  local hunk = current_hunk()
  if not hunk then
    notify("No Alma review hunk in the current buffer", vim.log.levels.WARN)
    return nil
  end
  if vim.ui and vim.ui.input then
    vim.ui.input({ prompt = "Alma hunk comment: " }, function(input)
      if input ~= nil then
        set_current_hunk_state("commented", input)
      end
    end)
    return hunk
  end
  return set_current_hunk_state("commented", "")
end

function M.approve_current_file()
  return set_file_hunks_state(nil, "approved")
end

function M.reject_current_file()
  return set_file_hunks_state(nil, "rejected")
end

function M.current_hunk()
  return current_hunk()
end

function M.review_items()
  local items = {}
  local proposal_ids = vim.tbl_keys(state.proposals)
  table.sort(proposal_ids)
  for _, proposal_id in ipairs(proposal_ids) do
    local proposal = state.proposals[proposal_id]
    table.insert(items, {
      kind = "proposal",
      text = proposal.title or proposal.id,
      proposal_id = proposal.id,
      proposal = proposal,
      file = proposal.files[1] and proposal.files[1].path or nil,
      pos = proposal.hunks[1] and { proposal.hunks[1].anchor_line or proposal.hunks[1].old_start or 1, 0 } or nil,
    })
    for _, file in ipairs(proposal.files or {}) do
      table.insert(items, {
        kind = "file",
        text = (file.relative_path or file.path) .. " (" .. tostring(#file.hunks) .. " hunks)",
        proposal_id = proposal.id,
        file_id = file.id,
        file_record = file,
        file = file.path,
        pos = file.hunks[1] and { file.hunks[1].anchor_line or file.hunks[1].old_start or 1, 0 } or nil,
      })
      for _, hunk in ipairs(file.hunks or {}) do
        table.insert(items, {
          kind = "hunk",
          text = string.format("%s %s %s", hunk.id, hunk.state or "pending", hunk.header),
          proposal_id = proposal.id,
          file_id = file.id,
          hunk_id = hunk.id,
          hunk = hunk,
          file = file.path,
          pos = { hunk.anchor_line or hunk.old_start or 1, 0 },
        })
      end
    end
  end
  return items
end

function M.goto_hunk(hunk_id, proposal_id)
  local hunk = find_hunk(hunk_id, proposal_id)
  if not hunk then
    return nil, "hunk not found: " .. tostring(hunk_id)
  end
  if normalize_path(vim.api.nvim_buf_get_name(0)) ~= normalize_path(hunk.path) then
    vim.cmd("edit " .. vim.fn.fnameescape(hunk.path))
  end
  local bufnr = vim.api.nvim_get_current_buf()
  render_all_reviews_for_path(hunk.path)
  local line = math.max(1, math.min(hunk.anchor_line or hunk.old_start or 1, vim.api.nvim_buf_line_count(bufnr)))
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  return true
end

function M.goto_item(item)
  if type(item) ~= "table" then
    return nil, "no item selected"
  end
  if item.hunk_id then
    return M.goto_hunk(item.hunk_id, item.proposal_id)
  end
  if item.file then
    if normalize_path(vim.api.nvim_buf_get_name(0)) ~= normalize_path(item.file) then
      vim.cmd("edit " .. vim.fn.fnameescape(item.file))
    end
    render_all_reviews_for_path(item.file)
    if item.pos then
      vim.api.nvim_win_set_cursor(0, { math.max(1, item.pos[1]), item.pos[2] or 0 })
    end
    return true
  end
  return nil, "item has no target"
end

function M.next_hunk()
  local hunks = current_buffer_review_hunks()
  if #hunks == 0 then
    notify("No Alma review hunks in the current buffer", vim.log.levels.WARN)
    return nil
  end
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  for _, hunk in ipairs(hunks) do
    if (hunk.anchor_line or hunk.old_start or 1) > cursor_line then
      return M.goto_hunk(hunk.id, hunk.proposal_id)
    end
  end
  return M.goto_hunk(hunks[1].id, hunks[1].proposal_id)
end

function M.previous_hunk()
  local hunks = current_buffer_review_hunks()
  if #hunks == 0 then
    notify("No Alma review hunks in the current buffer", vim.log.levels.WARN)
    return nil
  end
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  for i = #hunks, 1, -1 do
    local hunk = hunks[i]
    if (hunk.anchor_line or hunk.old_start or 1) < cursor_line then
      return M.goto_hunk(hunk.id, hunk.proposal_id)
    end
  end
  local hunk = hunks[#hunks]
  return M.goto_hunk(hunk.id, hunk.proposal_id)
end

function M.open_review_picker()
  local ok, picker = pcall(require, "util.alma_zk_review_picker")
  if ok and type(picker.open) == "function" then
    return picker.open()
  end
  command_review_list()
  notify("Snacks picker is unavailable; use :ZkAlmaReviewGoto <hunk-id> or ]h/[h")
end

function M.generate_for_thread(thread_id)
  local binding = state.thread_bindings[thread_id]
  if not binding then
    return nil, "thread is not bound"
  end
  local workspace = workspace_for_id(binding.workspace_id)
  if not workspace then
    return nil, "workspace is unavailable"
  end
  local payload = build_attachment_payload(thread_id, workspace, binding)
  return write_attachment_json(workspace, thread_id, payload)
end

function M.setup()
  if state.setup_done then
    try_register_hooks()
    return
  end
  state.setup_done = true

  vim.api.nvim_create_user_command("ZkAlmaWorkspaceRegister", command_workspace_register, {
    nargs = "?",
    complete = complete_workspaces,
    desc = "Register the current or named ZK workspace for Alma blackboard mode",
  })

  vim.api.nvim_create_user_command("ZkAlmaBlackboardBind", command_blackboard_bind, {
    nargs = "*",
    complete = complete_workspaces,
    desc = "Bind an Alma thread to a registered ZK workspace",
  })

  vim.api.nvim_create_user_command("ZkAlmaBlackboardUnbind", command_blackboard_unbind, {
    nargs = "?",
    desc = "Unbind an Alma thread from ZK blackboard mode",
  })

  vim.api.nvim_create_user_command("ZkAlmaBlackboardStatus", command_status, {
    desc = "Show ZK Alma blackboard workspace and thread binding status",
  })

  vim.api.nvim_create_user_command("ZkAlmaReviewApprove", command_review_approve, {
    nargs = "?",
    desc = "Approve the current or named Alma proposal hunk",
  })
  vim.api.nvim_create_user_command("ZkAlmaReviewReject", command_review_reject, {
    nargs = "?",
    desc = "Reject the current or named Alma proposal hunk",
  })
  vim.api.nvim_create_user_command("ZkAlmaReviewComment", command_review_comment, {
    nargs = "*",
    desc = "Comment the current or named Alma proposal hunk",
  })
  vim.api.nvim_create_user_command("ZkAlmaReviewApplyApproved", command_review_apply, {
    nargs = "?",
    desc = "Apply approved Alma proposal hunks after the review gate passes",
  })
  vim.api.nvim_create_user_command("ZkAlmaReviewGate", command_review_gate, {
    nargs = "?",
    desc = "Check whether an Alma proposal can be applied",
  })
  vim.api.nvim_create_user_command("ZkAlmaReviewPicker", command_review_picker, {
    desc = "Navigate Alma review proposals, files, and hunks",
  })
  vim.api.nvim_create_user_command("ZkAlmaReviewList", command_review_list, {
    desc = "List Alma review hunks for command-based navigation",
  })
  vim.api.nvim_create_user_command("ZkAlmaReviewGoto", command_review_goto, {
    nargs = "+",
    desc = "Jump to an Alma review hunk",
  })
  vim.api.nvim_create_user_command("ZkAlmaReviewNext", function()
    M.next_hunk()
  end, {
    desc = "Jump to the next Alma review hunk",
  })
  vim.api.nvim_create_user_command("ZkAlmaReviewPrev", function()
    M.previous_hunk()
  end, {
    desc = "Jump to the previous Alma review hunk",
  })
  vim.api.nvim_create_user_command("ZkAlmaReviewClear", command_review_clear, {
    nargs = "?",
    desc = "Clear Alma review overlays and state",
  })

  local group = vim.api.nvim_create_augroup("ZkAlmaBlackboard", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "AlmaBeforeSubmit",
    callback = function(event)
      if not state.hooks_registered then
        on_before_submit(event.data)
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "AlmaAfterSubmit",
    callback = function(event)
      on_after_submit(event.data)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "AlmaProposalReceived",
    callback = function(event)
      if not state.hooks_registered then
        on_proposal_received(event.data)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
    group = group,
    callback = function(event)
      render_all_reviews_for_path(vim.api.nvim_buf_get_name(event.buf))
    end,
  })

  try_register_hooks()
end

function M._state()
  return state
end

function M._reset()
  state.current_workspace_id = nil
  state.workspaces = {}
  state.thread_bindings = {}
  state.snapshots = {}
  state.proposals = {}
  state.review_feedback = {}
  state.rpc_sync = {}
  state.last_attachment = {}
  state.setup_done = false
  state.hooks_registered = false
end

return M
