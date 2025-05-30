local M = {}

--- @class DobuleChainNode
--- @field filepath string
--- @field filename string
local double_chain = { filepath = "", filename = "" }

-- Centralized configuration
local config = {
  notes_directory = vim.fn.expand("~/personal-wiki/"),
  cache_validity = {
    forward_links = 10, -- seconds
    backward_links = 30, -- seconds
    file_check_interval = 10, -- seconds
  },
}

-- Cache to store previous results and avoid repeated expensive operations
local results_cache = {
  forward_links = {},
  backward_links = {},
  graph = {},
  timestamp = {},
  last_file_check = 0,
  file_mtimes = {},
}

local function convert_to_absolute_path(path)
  if not path:match("^/") then
    return config.notes_directory .. path:gsub("^%./", "")
  else
    return path
  end
end

local function execute_rg_command(command)
  local output = {}
  local job_id = vim.fn.jobstart(command, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line and line ~= "" then
            table.insert(output, line)
          end
        end
      end
    end,
    stdout_buffered = true,
  })

  -- More efficient timeout handling
  local timeout_ms = 200
  local start_time = vim.loop.hrtime() / 1000000 -- Convert to ms

  while vim.fn.jobwait({ job_id }, 0)[1] == -1 do
    if (vim.loop.hrtime() / 1000000 - start_time) > timeout_ms then
      vim.fn.jobstop(job_id)
      vim.notify("Command execution timed out after " .. timeout_ms .. "ms", vim.log.levels.WARN)
      return ""
    end
    vim.cmd("sleep 5m")
  end

  return #output > 0 and table.concat(output, "\n") or ""
end

local function files_have_changed()
  local current_time = os.time()

  -- Only check once every 10 seconds at most
  if current_time - results_cache.last_file_check < 10 then
    return false
  end

  -- Get list of markdown files
  local command = string.format(
    "find %s -name '*.md' -type f -newer \"%s%s\"",
    config.notes_directory,
    config.notes_directory,
    ".last_check_timestamp"
  )

  local output = execute_rg_command(command)

  -- Update timestamp file
  os.execute(string.format("touch %s%s", config.notes_directory, ".last_check_timestamp"))
  results_cache.last_file_check = current_time

  -- If we found any files newer than our timestamp, cache is invalidated
  return output and output ~= ""
end

-- Hack: Use a unexpected output for avoid bad dir
function double_chain:backward()
  local filepath = self.filepath
  local filename = self.filename .. ".md"
  local directory = filepath:match("(.*/)")
  if not directory then
    vim.notify("Invalid filepath", vim.log.levels.ERROR)
    return {}
  end

  -- Check cache first
  local cache_key = filepath .. "_backward"
  if
    results_cache.backward_links[cache_key]
    and results_cache.timestamp[cache_key]
    and (os.time() - results_cache.timestamp[cache_key] < 30)
    and not files_have_changed()
  then
    return results_cache.backward_links[cache_key]
  end

  -- Optimized ripgrep command - only capture what we need
  local command = string.format("rg -o --no-line-number '^.*\\[.*?\\]\\((./%s)' %s", filename, directory)
  local result = execute_rg_command(command)
  local files_with_text = {}
  for line in result:gmatch("[^\r\n]+") do
    local out_filepath = line:match("^([^:]+)")
    if out_filepath then
      table.insert(files_with_text, convert_to_absolute_path(out_filepath))
    end
  end

  -- Cache results
  results_cache.backward_links[cache_key] = files_with_text
  results_cache.timestamp[cache_key] = os.time()

  return files_with_text
end

function double_chain:forward()
  local filepath = self.filepath

  local cache_key = filepath .. "_forward"
  if
    results_cache.forward_links[cache_key]
    and results_cache.timestamp[cache_key]
    and (os.time() - results_cache.timestamp[cache_key] < 10)
    and not files_have_changed()
  then -- 30s cache validity
    return results_cache.forward_links[cache_key]
  end

  -- Optimized command to extract only what we need
  local command = string.format("rg -o --no-line-number '\\[.*?\\]\\((.*?\\.md)\\)' %s", filepath)
  local result = execute_rg_command(command)
  local links = {}
  for link in result:gmatch("%((.-)%)") do
    table.insert(links, convert_to_absolute_path(link))
  end

  -- Cache results
  results_cache.forward_links[cache_key] = links
  results_cache.timestamp[cache_key] = os.time()

  return links
end

--- @class DoubleChainGraph
--- @field node DobuleChainNode
--- @field distance number

--- @param start_node DobuleChainNode
--- @param max_distance number
--- @return table<string, DoubleChainGraph>
-- function double_chain:find_all_related(start_node, max_distance)
--   max_distance = max_distance or math.huge
--   start_node = start_node or self
--   local start_path = convert_to_absolute_path(start_node.filepath)
--
--   local cache_key = start_path .. "_graph_" .. tostring(max_distance)
--
--   local graph = {}
--
--   local visited = {}
--   local queue = { { node = start_node, distance = 1 } }
--
--   while #queue > 0 do
--     local batch_size = math.min(10, #queue)
--     local batch = {}
--
--     for _ = 1, batch_size do
--       table.insert(batch, table.remove(queue, 1))
--     end
--
--     for _, current in ipairs(batch) do
--       local current_node = self
--       current_node.filepath = convert_to_absolute_path(current.node.filepath)
--       current_node.filename = vim.fn.fnamemodify(current.node.filepath, ":t:r")
--       local current_path = current_node.filepath
--
--       if not visited[current_path] and current.distance <= max_distance then
--         visited[current_path] = current.distance
--
--         -- if not use_cache or current.distance == 1 then
--         -- For level 1 connections or full recalculation, compute links
--         graph[current_path] = { links = {}, distance = current.distance }
--
--         -- Get forward and backward links
--         local forward_links = current_node:forward()
--         local backward_links = current_node:backward()
--
--         -- Process backward links
--         for _, link in ipairs(backward_links) do
--           if not graph[link] then
--             graph[link] = { links = {}, distance = nil }
--           end
--           table.insert(graph[link].links, current_path)
--           if not visited[link] then
--             table.insert(queue, {
--               node = { filepath = link, filename = vim.fn.fnamemodify(link, ":t:r") },
--               distance = current.distance + 1,
--             })
--           end
--         end
--
--         -- Process forward links
--         for _, link in ipairs(forward_links) do
--           if not visited[link] then
--             table.insert(queue, {
--               node = { filepath = link, filename = vim.fn.fnamemodify(link, ":t:r") },
--               distance = current.distance + 1,
--             })
--           end
--           -- end
--         end
--       end
--     end
--   end
--
--   -- Cache the results
--   results_cache.graph[cache_key] = graph
--   results_cache.timestamp[cache_key] = os.time()
--
--   print(vim.inspect(graph))
--   return graph
-- end

---@class ShortestPath
---@field node string
---@field path_length number

---@return ShortestPath[]
function double_chain:calculate_shortest_paths(start_node, max)
  max = max or math.huge
  local graph = self:find_all_related(start_node, max) or {}
  graph = graph or {}

  local shortest_paths = {}

  for _, data in pairs(graph) do
    for i = 1, #data do
      table.insert(shortest_paths, { node = data[i].links.filepath, path_length = data[i].distance })
    end
  end

  table.sort(shortest_paths, function(a, b)
    return a.path_length < b.path_length
  end)

  return shortest_paths
end

function double_chain:find_all_related(start_node, max_distance)
  local rust_processor = require("utils.tree_builder").generate_double_chain_graph(start_node, 10)
  return rust_processor
end

local function show_buffer_inlines_menu(opt, max)
  require("util.note_telescope").double_chain_search(opt, max + 1)
end

M.show_buffer_inlines_menu = show_buffer_inlines_menu
M.double_chain = double_chain

return M
