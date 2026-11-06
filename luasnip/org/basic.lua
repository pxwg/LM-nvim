local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local line_begin = require("luasnip.extras.expand_conditions").line_begin

local excluded = {
  block = true,
  drawer = true,
  property_drawer = true,
  inline_math_block = true,
  display_math_block = true,
  inline_code_block = true,
  latex_env = true,
  comment = true,
}

local function in_prose(_, matched_trigger)
  if vim.bo.filetype ~= "org" then
    return false
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local ok, node = pcall(vim.treesitter.get_node, {
    pos = { cursor[1] - 1, math.max(0, cursor[2] - #(matched_trigger or "")) },
    ignore_injections = true,
  })
  if not ok or not node then
    return false
  end
  while node do
    if excluded[node:type()] then
      return false
    end
    node = node:parent()
  end
  return true
end

return {
  s(
    { trig = "km", wordTrig = true, snippetType = "autosnippet" },
    { t("$"), i(1), t("$"), i(0) },
    { condition = in_prose }
  ),
  s(
    { trig = "eqs", wordTrig = true, snippetType = "autosnippet" },
    { t({ "#+begin_src typst", "$", "  " }), i(1), t({ "", "$", "#+end_src", "" }), i(0) },
    {
      condition = function(line_to_cursor, matched_trigger, captures)
        return line_begin(line_to_cursor, matched_trigger, captures) and in_prose(line_to_cursor, matched_trigger)
      end,
    }
  ),
}
