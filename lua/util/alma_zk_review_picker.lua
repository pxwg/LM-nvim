local M = {}

local function format_item(item)
  local icon = item.kind == "proposal" and "P" or item.kind == "file" and "F" or "H"
  local hl = item.kind == "hunk" and "SnacksPickerSpecial" or "SnacksPickerFile"
  return {
    { icon .. " ", "SnacksPickerIcon" },
    { item.text or item.kind, hl },
  }
end

local function fallback(items)
  local lines = { "Alma review navigation:" }
  for _, item in ipairs(items) do
    if item.kind == "hunk" then
      table.insert(lines, string.format("  :ZkAlmaReviewGoto %s %s", item.proposal_id, item.hunk_id))
    elseif item.kind == "file" then
      table.insert(lines, string.format("  file %s", item.text))
    elseif item.kind == "proposal" then
      table.insert(lines, string.format("  proposal %s", item.proposal_id))
    end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

function M.open()
  local review = require("util.alma_zk_blackboard")
  local items = review.review_items()
  if #items == 0 then
    vim.notify("[zk-alma] No proposal review items", vim.log.levels.INFO)
    return
  end

  if type(_G.Snacks) ~= "table" or type(_G.Snacks.picker) ~= "table" then
    fallback(items)
    return
  end

  _G.Snacks.picker.pick({
    title = "Alma Proposals",
    items = items,
    format = format_item,
    confirm = function(picker, item)
      picker:close()
      if item then
        local ok, err = review.goto_item(item)
        if not ok then
          vim.notify("[zk-alma] " .. tostring(err), vim.log.levels.WARN)
        end
      end
    end,
  })
end

return M
