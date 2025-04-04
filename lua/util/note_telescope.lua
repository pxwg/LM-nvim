local M = {}
local finders = require("telescope.finders")
local image_preview = require("util.telescope-figure")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local sorters = require("telescope.sorters")
local telescope = require("telescope")

local double_chain = require("util.note_node_get_graph").double_chain

--- Use telescope to search for links in the double chain graph
--- @param opts table
--- @param max number
local function double_chain_search(opts, max)
  opts = opts or { width = 0.5 }
  local start_node = { filepath = vim.fn.expand("%:p"), filename = vim.fn.expand("%:t:r") }
  local sorted_results = double_chain:calculate_shortest_paths(start_node, max)
  table.sort(sorted_results, function(a, b)
    return a.path_length < b.path_length
  end)

  pickers
    .new(opts, {
      prompt_title = "Links",
      finder = finders.new_table({
        results = vim.tbl_map(
          function(item)
            item.path_length = item.path_length - 1
            return {
              display = item.path_length .. "   " .. vim.fn.fnamemodify(item.node, ":t"),
              value = item.node,
            }
          end,
          -- sorted_results
          vim.tbl_filter(function(item)
            return item.path_length > 1
          end, sorted_results)
        ),
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      }),
      sorter = sorters.get_fzy_sorter(),

      previewer = previewers.new_buffer_previewer({
        title = "Preview",
        define_preview = function(self, entry, status)
          local filepath = entry.value
          if filepath then
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.fn.readfile(filepath))
          end
        end,
      }),
      file_previewer = image_preview.file_previewer,
      buffer_previewer_maker = image_preview.buffer_previewer_maker,
      attach_mappings = function(prompt_bufnr, map)
        local actions = require("telescope.actions")
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = require("telescope.actions.state").get_selected_entry()
          if selection then
            vim.cmd("edit " .. selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

local function double_chain_insert(opts, max)
  opts = opts or { width = 0.5 }
  local start_node = { filepath = vim.fn.expand("%:p"), filename = vim.fn.expand("%:t:r") }
  local sorted_results = double_chain:calculate_shortest_paths(start_node, max + 1)
  table.sort(sorted_results, function(a, b)
    return a.path_length < b.path_length
  end)

  pickers
    .new(opts, {
      prompt_title = "Links",
      finder = finders.new_table({
        results = vim.tbl_map(
          function(item)
            item.path_length = item.path_length - 1
            return {
              display = item.path_length .. "   " .. vim.fn.fnamemodify(item.node, ":t"),
              value = item.node,
            }
          end,
          vim.tbl_filter(function(item)
            return item.path_length > 1
          end, sorted_results)
        ),
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      }),
      sorter = sorters.get_fzy_sorter(),

      previewer = previewers.new_buffer_previewer({
        title = "Preview",
        define_preview = function(self, entry, status)
          local filepath = entry.value
          if filepath then
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.fn.readfile(filepath))
          end
        end,
      }),
      file_previewer = image_preview.file_previewer,
      buffer_previewer_maker = image_preview.buffer_previewer_maker,
      attach_mappings = function(prompt_bufnr, map)
        local actions = require("telescope.actions")
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = require("telescope.actions.state").get_selected_entry()
          if selection then
            local relative_selected_path =
              require("util.note_node").get_relative_note_path(selection.value, start_node.filepath)
            local selected_name = vim.fn.fnamemodify(selection.value, ":t:r")
            local formatted_string = string.format("- [%s](%s)", selected_name, relative_selected_path)
            vim.api.nvim_put({ formatted_string }, "l", true, true)
          else
            vim.notify("No selection made", vim.log.levels.WARN)
          end
        end)
        return true
      end,
    })
    :find()
end

M.double_chain_search = double_chain_search
M.double_chain_insert = double_chain_insert

return M
