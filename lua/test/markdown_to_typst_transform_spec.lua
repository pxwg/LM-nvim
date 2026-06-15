local transforms = require("user.transforms")
local mitex = require("util.mitex")

local tests = {}

local function test(name, fn)
  tests[#tests + 1] = { name = name, fn = fn }
end

local function assert_contains(haystack, needle, message)
  if haystack:find(needle, 1, true) == nil then
    error(("%s\nmissing: %s\nin: %s"):format(message, vim.inspect(needle), vim.inspect(haystack)), 2)
  end
end

local function assert_not_contains(haystack, needle, message)
  if haystack:find(needle, 1, true) ~= nil then
    error(("%s\nunexpected: %s\nin: %s"):format(message, vim.inspect(needle), vim.inspect(haystack)), 2)
  end
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function convert_latex(latex)
  local converted, err = mitex.convert_latex(latex)
  if not converted then
    error("mitex failed for " .. vim.inspect(latex) .. ": " .. err)
  end
  return vim.trim(converted)
end

test("mitex converts inline and block raw calls in text", function()
  local inline = convert_latex("x^2")
  local block = convert_latex("y^2")
  local converted, err = mitex.convert_text(table.concat({
    "before #mitex(```x^2```) after",
    "",
    "#mitex(",
    "```",
    "y^2",
    "```",
    ")",
    "",
  }, "\n"))

  if not converted then
    error(err)
  end

  assert_contains(converted, "$" .. inline .. "$", "inline #mitex call should become inline Typst math")
  assert_contains(converted, block, "block #mitex call should be converted through MiTeX")
  assert_not_contains(converted, "#mitex", "mitex placeholders should be removed")
end)

test("markdown_to_typst converts markdown with dollar and backslash math delimiters", function()
  local output = transforms.markdown_to_typst({
    text = table.concat({
      "# Title",
      "",
      "Inline $x^2$ and \\(y+1\\).",
      "",
      "$$",
      "\\frac{a}{b}",
      "$$",
      "",
      "\\[",
      "z^2",
      "\\]",
      "",
    }, "\n"),
    regtype = "V",
  })

  local text = output.text
  assert_equal(output.regtype, "V", "transform should preserve Porter register type")
  assert_contains(text, "= Title", "markdown body should be converted by Pandoc")
  assert_contains(text, "$" .. convert_latex("x^2") .. "$", "dollar inline math should become pure Typst math")
  assert_contains(text, "$" .. convert_latex("y+1") .. "$", "backslash inline math should become pure Typst math")
  assert_contains(text, convert_latex("\\frac{a}{b}"), "dollar display math should become pure Typst math")
  assert_contains(text, convert_latex("z^2"), "backslash display math should become pure Typst math")
  assert_not_contains(text, "#mitex", "final Typst should not contain mitex placeholders")
  assert_not_contains(text, "\\frac", "final Typst should not contain original LaTeX display source")
end)

local failures = {}

for _, case in ipairs(tests) do
  local ok, err = xpcall(case.fn, debug.traceback)
  if ok then
    vim.api.nvim_out_write("PASS " .. case.name .. "\n")
  else
    failures[#failures + 1] = ("FAIL %s\n%s"):format(case.name, err)
  end
end

if #failures > 0 then
  vim.api.nvim_err_writeln(table.concat(failures, "\n\n"))
  vim.cmd("cquit 1")
end

vim.api.nvim_out_write(("markdown_to_typst_transform_spec.lua: %d tests passed\n"):format(#tests))
