local M = {}
local finders = require("telescope.finders")
local image_preview = require("util.telescope-figure")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local sorters = require("telescope.sorters")
local telescope = require("telescope")

local double_chain = require("util.note_node_get_graph").double_chain

local function double_chain_search(opts)
  opts = opts or { width = 0.5 }
  local start_node = { filepath = vim.fn.expand("%:p"), filename = vim.fn.expand("%:t:r") }
  local sorted_results = double_chain:calculate_shortest_paths(start_node, 3)
  table.sort(sorted_results, function(a, b)
    return a.path_length < b.path_length
  end)

  pickers
    .new(opts, {
      prompt_title = "Links",
      finder = finders.new_table({
        results = vim.tbl_map(function(item)
          return {
            display = "  " .. vim.fn.fnamemodify(item.node, ":t"),
            value = item.node,
          }
        end, sorted_results),
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

M.double_chain_search = double_chain_search

return M
