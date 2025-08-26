-- Language configuration manager
-- Loads and manages language-specific configurations

local M = {}

-- Available language modules
M.languages = {
  "tex",
  "markdown", 
  "typst"
}

-- Load all language configurations
M.setup = function()
  for _, lang in ipairs(M.languages) do
    local ok, lang_module = pcall(require, "languages." .. lang)
    if ok and lang_module.setup then
      lang_module.setup()
    else
      vim.notify("Failed to load language configuration: " .. lang, vim.log.levels.WARN)
    end
  end
end

return M