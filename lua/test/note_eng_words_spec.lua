local M = require("util.note_eng_words")

local function test_extract_words()
  local tests = {
    {
      name = "Basic case",
      input = "* hello 你好 我是小企鹅",
      expected = { { "hello", "你好 我是小企鹅" } },
    },
    {
      name = "Combination case",
      input = "- Smash *打破* + through 快速打破",
      expected = { { "Smash", "打破" }, { "Smash through", "快速打破" } },
    },
    {
      name = "Multiple definitions case",
      input = "- counternance 面容 keep one's counternance 保持镇定 out of counternance 不安",
      expected = {
        { "counternance", "面容" },
        { "keep one's counternance", "保持镇定" },
        { "out of counternance", "不安" },
      },
    },
    {
      name = "Mixed spacing",
      input = "*   word   释义 ",
      expected = { { "word", "释义" } },
    },
    {
      name = "No English word",
      input = "*  释义",
      expected = {},
    },
    {
      name = "No Chinese definition",
      input = "* word",
      expected = {},
    },
    {
      name = "Bracket in definition",
      input = "* word (释义) 你好世界 (释义)",
      expected = { { "word", "(释义) 你好世界 (释义)" } },
    },
    {
      name = "Bracket in definition",
      input = "* word 你好世界 (释义)",
      expected = { { "word", "你好世界 (释义)" } },
    },
    {
      name = "Multiple words in definition and abba.",
      input = "word n. (词性) 释义",
      expected = { "word", "n. (词性) 释义" },
    },
    {
      name = "Multiple words in definition and abba.",
      input = "word  (词性) 释义",
      expected = { "word", "(词性) 释义" },
    },
    {
      name = "Multiple spaces in definition",
      input = "* word 你好   世界",
      expected = { { "word", "你好   世界" } },
    },
  }

  local success = true
  local failures = {}

  -- Mock vim API functions
  local original_buf_get_lines = vim.api.nvim_buf_get_lines
  vim.api.nvim_buf_get_lines = function(_, _, _, _)
    return { current_test_input }
  end

  for _, test in ipairs(tests) do
    print("Running test: " .. test.name)
    current_test_input = test.input

    local result = M.extract_words()
    local passed = #result == #test.expected

    if passed then
      for i, pair in ipairs(result) do
        if pair[1] ~= test.expected[i][1] or pair[2] ~= test.expected[i][2] then
          passed = false
          break
        end
      end
    end

    if passed then
      print("  ✓ PASSED")
    else
      success = false
      print("  ✗ FAILED")
      table.insert(failures, {
        name = test.name,
        expected = test.expected,
        got = result,
      })
    end
  end

  -- Restore original function
  vim.api.nvim_buf_get_lines = original_buf_get_lines

  print("\nTest summary:")
  if success then
    print("All tests passed!")
  else
    print(#failures .. " test(s) failed:")
    for _, failure in ipairs(failures) do
      print("- " .. failure.name)
      print("  Expected: " .. vim.inspect(failure.expected))
      print("  Got: " .. vim.inspect(failure.got))
    end
  end

  return success
end

-- Run tests
test_extract_words()

return {
  test_extract_words = test_extract_words,
}
