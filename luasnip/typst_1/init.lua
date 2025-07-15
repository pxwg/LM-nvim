-- Typst snippets main loader
local M = {}

-- Load all Typst snippet files
local snippet_files = {
  "basic",
  "symbols",
  "derivatives",
  "matrices",
  "fonts",
  "templates",
}

-- Combine all snippets
local all_snippets = {}

for _, file in ipairs(snippet_files) do
  local ok, snippets = pcall(require, "luasnip.typst." .. file)
  if ok and snippets then
    vim.list_extend(all_snippets, snippets)
  else
    vim.notify("Failed to load Typst snippets from " .. file, vim.log.levels.WARN)
  end
end

return all_snippets
