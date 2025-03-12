local M = {}

local function convert_to_absolute_path(path)
  local root_directory = "/Users/pxwg-dogggie/personal-wiki/"
  if not path:match("^/") then
    return root_directory .. path:gsub("^%./", "")
  else
    return path
  end
end

--- @class DobuleChainNode
--- @field filepath string
--- @field filename string
local double_chain = { filepath = "", filename = "" }

local function execute_rg_command(command)
  -- local handle = io.popen(command)
  local handle = vim.fn.system(command)
  if handle then
    -- local result = handle:read("*a")
    return handle
  else
    vim.notify("Command execution failed", vim.log.levels.ERROR)
    return ""
  end
end

function double_chain:backward()
  local filepath = self.filepath
  local filename = self.filename .. ".md"
  local directory = filepath:match("(.*/)")
  if not directory then
    vim.notify("Invalid filepath", vim.log.levels.ERROR)
    return {}
  end

  local command = string.format("rg -l '\\(./%s\\)' %s", filename, directory)
  local result = execute_rg_command(command)
  local files_with_text = {}
  for file in result:gmatch("[^\r\n]+") do
    table.insert(files_with_text, convert_to_absolute_path(file))
  end
  return files_with_text
end

function double_chain:forward()
  local filepath = self.filepath
  local command = string.format("rg -o '\\[.*?\\]\\((.*?.md)\\)' %s", filepath)
  local result = execute_rg_command(command)
  local links = {}
  for link in result:gmatch("%((.-)%)") do
    table.insert(links, convert_to_absolute_path(link))
  end
  return links
end

function double_chain:find_all_related(start_node, max_distance)
  max_distance = max_distance or math.huge
  start_node = start_node or self
  local visited = {}
  local queue = { { node = start_node, distance = 1 } }
  local graph = {}

  while #queue > 0 do
    local current = table.remove(queue, 1)
    local current_node = self
    current_node.filepath = convert_to_absolute_path(current.node.filepath)
    current_node.filename = vim.fn.fnamemodify(current.node.filepath, ":t:r")
    local current_path = current_node.filepath

    if not visited[current_path] then
      visited[current_path] = current.distance

      if current.distance > max_distance then
        break
      end

      local forward_links = current_node:forward()
      graph[current_path] = { links = forward_links or {}, distance = current.distance }

      local backward_links = current_node:backward()
      for _, link in ipairs(backward_links) do
        if not graph[link] then
          graph[link] = { links = {}, distance = nil }
        end
        table.insert(graph[link].links, current_path)
        if not visited[link] then
          table.insert(
            queue,
            { node = { filepath = link, filename = vim.fn.fnamemodify(link, ":t:r") }, distance = current.distance + 1 }
          )
        end
      end

      for _, link in ipairs(forward_links) do
        if not visited[link] then
          table.insert(
            queue,
            { node = { filepath = link, filename = vim.fn.fnamemodify(link, ":t:r") }, distance = current.distance + 1 }
          )
        end
      end
    end
  end

  return graph
end

---@class ShortestPath
---@field node string
---@field path_length number

---@return ShortestPath[]
function double_chain:calculate_shortest_paths(start_node, max)
  max = max or math.huge
  local graph = self:find_all_related(start_node, max) or {}
  graph = graph or {}

  local shortest_paths = {}

  for node, data in pairs(graph) do
    table.insert(shortest_paths, { node = node, path_length = data.distance or math.huge })
  end

  table.sort(shortest_paths, function(a, b)
    return a.path_length < b.path_length
  end)

  return shortest_paths
end

local function show_buffer_inlines_menu(opt, max)
  require("util.note_telescope").double_chain_search(opt, max + 1)
end

M.show_buffer_inlines_menu = show_buffer_inlines_menu
M.double_chain = double_chain

return M
