local M = {}

local double_chain = require("util.note_node_get_graph").double_chain

--- Use Snacks.picker to search for links in the double chain graph
--- @param opts table
--- @param max number
local function double_chain_search(opts, max)
  local start_node = { filepath = vim.fn.expand("%:p"), filename = vim.fn.expand("%:t:r") }
  local sorted_results = double_chain:calculate_shortest_paths(start_node, max)
  table.sort(sorted_results, function(a, b)
    return a.path_length < b.path_length
  end)

  local filtered = vim.tbl_filter(function(item)
    return item.path_length > 1
  end, sorted_results)

  local items = vim.tbl_map(function(item)
    item.path_length = item.path_length - 1
    return {
      text = item.path_length .. "   " .. vim.fn.fnamemodify(item.node, ":t"),
      file = item.node,
    }
  end, filtered)

  Snacks.picker.pick({
    title = "Links",
    items = items,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd("edit " .. item.file)
      end
    end,
  })
end

local function double_chain_insert(opts, max)
  local start_node = { filepath = vim.fn.expand("%:p"), filename = vim.fn.expand("%:t:r") }
  local sorted_results = double_chain:calculate_shortest_paths(start_node, max + 1)
  table.sort(sorted_results, function(a, b)
    return a.path_length < b.path_length
  end)

  local filtered = vim.tbl_filter(function(item)
    return item.path_length > 1
  end, sorted_results)

  local items = vim.tbl_map(function(item)
    item.path_length = item.path_length - 1
    return {
      text = item.path_length .. "   " .. vim.fn.fnamemodify(item.node, ":t"),
      file = item.node,
    }
  end, filtered)

  Snacks.picker.pick({
    title = "Links",
    items = items,
    confirm = function(picker, item)
      picker:close()
      if item then
        local rel = require("util.note_node").get_relative_note_path(item.file, start_node.filepath)
        local name = vim.fn.fnamemodify(item.file, ":t:r")
        vim.api.nvim_put({ string.format("- [%s](%s)", name, rel) }, "l", true, true)
      else
        vim.notify("No selection made", vim.log.levels.WARN)
      end
    end,
  })
end

M.double_chain_search = double_chain_search
M.double_chain_insert = double_chain_insert

return M
