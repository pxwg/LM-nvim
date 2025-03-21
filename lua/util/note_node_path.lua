local M = {}

--- @class GraphTable
--- @field string table<string, table<string>>

--- @class ShortestPathResult
--- @field path string[]
--- @field length number
--- @return ShortestPathResult

-- bfs
--- @param graph GraphTable
--- @param start string
--- @param goal string
--- @return ShortestPathResult
local function bfs_shortest_path(graph, start, goal)
  if start == goal then
    return { path = { start }, length = 0 }
  end

  if not graph or not graph[start] or not graph[goal] then
    return { path = "", length = 10 }
  end

  local queue = { start }
  local visited = { [start] = true }
  local predecessors = { [start] = nil }

  while #queue > 0 do
    local current = table.remove(queue, 1)

    if current == goal then
      local path = {}
      local node = goal
      while node do
        table.insert(path, 1, node)
        node = predecessors[node]
      end
      return { path = path, length = #path - 1 }
    end

    if graph[current] == nil then
      print("man")
      return { path = "", length = math.huge }
    end
    for _, neighbor in ipairs(graph[current]) do
      if not visited[neighbor] then
        visited[neighbor] = true
        predecessors[neighbor] = current
        table.insert(queue, neighbor)
      end
    end
  end

  return { path = "", length = 10 }
end

M.bfs_shortest_path = bfs_shortest_path

return M
