local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local f = ls.function_node
local c = ls.choice_node
local i = ls.insert_node
local d = ls.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

-- Helper function to check if we're in a Typst file
local function in_typst()
  return vim.bo.filetype == "typst"
end

local function in_math()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, col)

  -- Check if we're inside $ ... $
  local dollar_before = 0
  for _ in before_cursor:gmatch("%$") do
    dollar_before = dollar_before + 1
  end

  return dollar_before % 2 == 1
end

-- Helper function to create derivative snippets
local differential = function(order)
  if order == 1 then
    return sn(
      nil,
      fmta([[(dif <>)/(dif <>)<>]], {
        i(1),
        i(2),
        i(0),
      })
    )
  else
    return sn(
      nil,
      fmta([[(dif^]] .. order .. [[ <>)/(dif <>^]] .. order .. [[)<>]], {
        i(1),
        i(2),
        i(0),
      })
    )
  end
end

local partial_differential = function(order)
  if order == 1 then
    return sn(
      nil,
      fmta([[(diff <>)/(diff <>)<>]], {
        i(1),
        i(2),
        i(0),
      })
    )
  else
    return sn(
      nil,
      fmta([[(diff^]] .. order .. [[ <>)/(diff <>^]] .. order .. [[)<>]], {
        i(1),
        i(2),
        i(0),
      })
    )
  end
end

local full_derivative = function(_, _, _, diff_type)
  local M = {}
  for i = 1, 9, 1 do
    if diff_type == "ordinary" then
      table.insert(M, differential(i))
    else
      table.insert(M, partial_differential(i))
    end
  end
  return sn(nil, { c(1, M) })
end

return {
  -- Ordinary derivatives
  s({
    trig = "diff",
    snippetType = "autosnippet",
    wordTrig = true,
  }, d(1, full_derivative, {}, { user_args = { "ordinary" } }), { condition = in_math }),

  -- Partial derivatives
  s({
    trig = "part",
    snippetType = "autosnippet",
    wordTrig = true,
  }, d(1, full_derivative, {}, { user_args = { "partial" } }), { condition = in_math }),

  -- Numbered ordinary derivatives
  s(
    {
      trig = "([2-9])diff",
      snippetType = "autosnippet",
      wordTrig = true,
      regTrig = true,
    },
    d(1, function(_, parent)
      return differential(tonumber(parent.snippet.captures[1]))
    end, {}),
    { condition = in_math }
  ),

  -- Numbered partial derivatives
  s(
    {
      trig = "([2-9])part",
      snippetType = "autosnippet",
      wordTrig = true,
      regTrig = true,
    },
    d(1, function(_, parent)
      return partial_differential(tonumber(parent.snippet.captures[1]))
    end, {}),
    { condition = in_math }
  ),

  -- Simple differential element
  s({
    trig = "dd",
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("dif "), { condition = in_math }),

  -- Partial differential symbol
  s({
    trig = "pp",
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("diff "), { condition = in_math }),

  -- Advanced fractions with binomial coefficients
  s({
    trig = "binom",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("binom(<>, <>)<>", { i(1), i(2), i(0) }), { condition = in_math }),

  -- Matrix/vector operations
  s({
    trig = "grad",
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("nabla"), { condition = in_math }),

  s({
    trig = "div",
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("nabla dot"), { condition = in_math }),

  s({
    trig = "curl",
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("nabla times"), { condition = in_math }),

  -- Laplacian
  s({
    trig = "lapl",
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("nabla^2"), { condition = in_math }),

  -- Common fraction shortcuts
  s({
    trig = "half",
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("1/2"), { condition = in_math }),

  s({
    trig = "third",
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("1/3"), { condition = in_math }),

  s({
    trig = "quarter",
    snippetType = "autosnippet",
    wordTrig = true,
  }, t("1/4"), { condition = in_math }),
}
