local M = {}

local function read_file(path)
  local fd = vim.uv.fs_open(path, "r", 438)
  if not fd then
    return nil
  end

  local stat = vim.uv.fs_fstat(fd)
  if not stat then
    vim.uv.fs_close(fd)
    return nil
  end

  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  return data
end

local function is_file(path)
  local stat = path and vim.uv.fs_stat(path) or nil
  return stat and stat.type == "file"
end

local function expand(path)
  return vim.fs.normalize(vim.fn.expand(path))
end

local function glob_skill_files(root)
  if not root or root == "" then
    return {}
  end

  local patterns = {
    vim.fs.joinpath(root, "*/SKILL.md"),
    vim.fs.joinpath(root, ".system/*/SKILL.md"),
  }
  local files = {}
  local seen = {}

  for _, pattern in ipairs(patterns) do
    for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
      path = vim.fs.normalize(path)
      if is_file(path) and not seen[path] then
        seen[path] = true
        table.insert(files, path)
      end
    end
  end

  return files
end

local function parse_frontmatter(content)
  if not content or not content:match("^%-%-%-%s*\n") then
    return {}, content or ""
  end

  local close_start, close_end = content:find("\n%-%-%-%s*\n", 4)
  if not close_start then
    return {}, content
  end

  local meta = {}
  local header = content:sub(5, close_start - 1)
  for line in header:gmatch("[^\r\n]+") do
    local key, value = line:match("^([%w_-]+):%s*(.*)$")
    if key and value then
      value = value:gsub('^"', ""):gsub('"$', "")
      meta[key] = value
    end
  end

  return meta, content:sub(close_end + 1)
end

local function skill_name_from_path(path)
  return vim.fn.fnamemodify(vim.fn.fnamemodify(path, ":h"), ":t")
end

local function tool_name_for(source, name)
  local prefix = "skill"
  if source:match("^project") then
    prefix = "project-skill"
  end

  local raw = prefix .. "-" .. name
  raw = raw:lower():gsub("[^%w_-]", "-"):gsub("_", "-"):gsub("-+", "-"):gsub("^%-", ""):gsub("%-$", "")
  return raw
end

local function source_tool_name_for(source, name)
  local raw = "skill-" .. source .. "-" .. name
  raw = raw:lower():gsub("[^%w_-]", "-"):gsub("_", "-"):gsub("-+", "-"):gsub("^%-", ""):gsub("%-$", "")
  return raw
end

local function add_skill(out, seen_tools, source, path)
  local content = read_file(path)
  if not content then
    return
  end

  local meta = parse_frontmatter(content)
  local name = meta.name or skill_name_from_path(path)
  local tool_name = tool_name_for(source, name)
  local unique_tool_name = tool_name

  if seen_tools[unique_tool_name] then
    unique_tool_name = source_tool_name_for(source, name)
  end

  local suffix = 2
  local base_unique_tool_name = unique_tool_name
  while seen_tools[unique_tool_name] do
    unique_tool_name = base_unique_tool_name .. "-" .. suffix
    suffix = suffix + 1
  end
  seen_tools[unique_tool_name] = true

  table.insert(out, {
    name = name,
    source = source,
    path = path,
    tool_name = unique_tool_name,
    description = meta.description or ("Load the " .. name .. " skill instructions."),
    content = content,
  })
end

local function project_skill_roots(cwd)
  cwd = cwd or vim.uv.cwd()
  return {
    { source = "project-codex", root = vim.fs.joinpath(cwd, ".codex/skills") },
    { source = "project-claude", root = vim.fs.joinpath(cwd, ".claude/skills") },
  }
end

local function global_skill_roots()
  return {
    { source = "codex", root = expand("~/.codex/skills") },
    { source = "claude", root = expand("~/.claude/skills") },
  }
end

function M.list(cwd)
  local out = {}
  local seen_tools = {}

  for _, entry in ipairs(project_skill_roots(cwd)) do
    for _, path in ipairs(glob_skill_files(entry.root)) do
      add_skill(out, seen_tools, entry.source, path)
    end
  end

  for _, entry in ipairs(global_skill_roots()) do
    for _, path in ipairs(glob_skill_files(entry.root)) do
      add_skill(out, seen_tools, entry.source, path)
    end
  end

  table.sort(out, function(a, b)
    if a.source == b.source then
      return a.name < b.name
    end
    return a.source < b.source
  end)

  return out
end

function M.copilot_functions(cwd)
  local functions = {}

  for _, skill in ipairs(M.list(cwd)) do
    functions[skill.tool_name] = {
      group = "skills",
      description = string.format("[%s] %s", skill.source, skill.description),
      schema = {
        type = "object",
        properties = {},
        required = {},
      },
      resolve = function()
        return {
          {
            uri = "skill://" .. skill.source .. "/" .. skill.name,
            name = skill.name,
            mimetype = "text/markdown",
            data = table.concat({
              "# Skill: " .. skill.name,
              "Source: " .. skill.source,
              "Path: " .. skill.path,
              "",
              skill.content,
            }, "\n"),
          },
        }
      end,
    }
  end

  return functions
end

return M
