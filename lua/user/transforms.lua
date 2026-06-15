local M = {}

local function pandoc_filter_path()
  return vim.fn.stdpath("config") .. "/lua/porter/pandoc_math_filter.lua"
end

local function run_pandoc_markdown_to_typst(markdown)
  local result = vim
    .system({
      "pandoc",
      "-f",
      "markdown+tex_math_dollars+tex_math_single_backslash",
      "-t",
      "typst",
      "--wrap=none",
      "--lua-filter=" .. pandoc_filter_path(),
    }, {
      stdin = markdown,
      text = true,
    })
    :wait()

  if result.code ~= 0 then
    error("pandoc markdown->typst failed: " .. vim.trim(result.stderr or result.stdout or ""))
  end

  return result.stdout or ""
end

function M.markdown_to_typst(ctx)
  local markdown = type(ctx) == "table" and ctx.text or tostring(ctx or "")
  local typst_with_mitex = run_pandoc_markdown_to_typst(markdown)
  local typst, err = require("util.mitex").convert_text(typst_with_mitex)

  if not typst then
    error("mitex markdown math conversion failed: " .. err)
  end

  return {
    text = typst,
    regtype = type(ctx) == "table" and ctx.regtype or "v",
  }
end

return M
