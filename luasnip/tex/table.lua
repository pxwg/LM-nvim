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
local line_begin = require("luasnip.extras.expand_conditions").line_begin
local tex = require("util.latex")

local gen_tab = function(ncol, nrow)
  local M = {}

  for x = 1, nrow, 1 do
    local N = {}
    table.insert(N, i(1 + (x - 1) * ncol))
    for y = 2, ncol, 1 do
      table.insert(N, t(" & "))
      table.insert(N, i(y + (x - 1) * ncol))
    end
    table.insert(N, t({ "\\\\", "\\hline", "" }))

    for _, v in ipairs(N) do
      table.insert(M, v)
    end
  end
  return sn(nil, M)
end

local gen_tab_1 = function(ncol, nrow)
  local M = {}

  for x = 1, nrow, 1 do
    local N = {}
    table.insert(N, i(1 + (x - 1) * ncol))
    for y = 2, ncol, 1 do
      table.insert(N, t(" & "))
      table.insert(N, i(y + (x - 1) * ncol))
    end
    table.insert(N, t({ "\\\\", "" }))

    for _, v in ipairs(N) do
      table.insert(M, v)
    end
  end
  return sn(nil, M)
end

local gen_tab_2 = function(ncol, nrow)
  local M = {}

  for x = 1, nrow, 1 do
    local N = {}
    table.insert(N, i(1 + (x - 1) * ncol))
    for y = 2, ncol, 1 do
      table.insert(N, t(" & "))
      table.insert(N, i(y + (x - 1) * ncol))
    end
    table.insert(N, t({ "\\\\", "\\hline", "" }))

    for _, v in ipairs(N) do
      table.insert(M, v)
    end
  end
  return sn(nil, M)
end

local gen_str = function(n)
  local pattern = "| >{\\centering\\arraybackslash}X "
  return string.rep(pattern, n)
end

return {

  s(
    {
      trig = [[ntab]],
      snippetType = "autosnippet",
      WordTrig = true,
      trigEngine = "pattern",
      -- priority = 5000,
    },
    fmta(
      [[
    \begin{table}[H]\label{<>}
      \caption{<>}
      \begin{center}
        tab<>
      \end{center}
    \end{table}<>
  ]],
      { i(1, "label"), i(2, "table caption"), i(3, " "), i(0) }
    ),
    {
      condition = tex.text,
    }
  ),

  -- s(
  --   {
  --     trig = [[Ntb]],
  --     snippetType = "autosnippet",
  --     WordTrig = true,
  --     trigEngine = "pattern",
  --     -- priority = 5000,
  --   },
  --   fmta(
  --     [[
  --   \begin{table}[H]
  --     \begin{center}
  --       tab:<>
  --     \end{center}
  --   \end{tabular}<>
  -- ]],
  --     { i(1), i(0) }
  --   ),
  --   {
  --     condition = tex.text,
  --   }
  -- ),
  -- 支持自定义表格宽度（不限制列数）
  s({
    trig = [[tab_(%d+)s]],
    snippetType = "autosnippet",
    -- wordTrig = true,
    trigEngine = "pattern",
    priority = 5000,
  }, {
    -- 配置表格宽度
    t({ "\\begin{xltabular}" }),
    t({ "{" }),
    i(1, "0.8"),
    t({ "\\textwidth}" }),
    t("{ | >{"),
    -- 自定义样式
    c(2, { t("\\centering"), t("\\raggedright"), t("\\raggedleft") }),
    t({ "\\arraybackslash}X " }),
    f(function(_, snip)
      return { gen_str(snip.captures[1] - 2), "" }
    end),
    t(" | >{"),
    c(3, { t("\\centering"), t("\\raggedright"), t("\\raggedleft") }),
    t({ "\\arraybackslash}X | }", "" }),

    -- 制作表头第一个
    t({ "", "\\caption{" }),
    i(4, "table caption"),
    t({ "}\\\\", "" }),
    t({ "\\hline", "" }),
    d(5, function(_, parent)
      return gen_tab_1(parent.snippet.captures[1], 1)
    end, {}, { user_args = {} }),
    t({ "\\endfirsthead", "" }),
    -- 制作表头第二个
    t({ "", "\\caption{" }),
    i(6, "table caption"),
    t({ "}\\\\", "" }),
    t({ "\\hline", "" }),
    d(7, function(_, parent)
      return gen_tab_1(parent.snippet.captures[1], 1)
    end, {}, { user_args = {} }),
    -- 尾巴
    t({ "\\endhead", "" }),
    t({ "\\endfoot", "" }),
    t({ "\\endlastfoot", "", "" }),
    -- 编辑表格基本结构，默认为全中心
    t({ "\\hline", "" }),
    t({ "\\hline", "" }),
    d(8, function(_, parent)
      return gen_tab(parent.snippet.captures[1], parent.snippet.captures[1])
    end, {}, { user_args = {} }),
    t({ "", "\\end{xltabular}" }),
    i(0),
  }, {
    condition = tex.in_text,
  }),

  s({
    trig = [[tab_(%d+),(%d+)s]],
    snippetType = "autosnippet",
    -- wordTrig = true,
    trigEngine = "pattern",
    priority = 5000,
  }, {
    -- 配置表格宽度
    t({ "\\begin{xltabular}" }),
    t({ "{" }),
    i(1, "0.8"),
    t({ "\\textwidth}" }),
    t("{ | >{"),
    -- 自定义样式
    c(2, { t("\\centering"), t("\\raggedright"), t("\\raggedleft") }),
    t({ "\\arraybackslash}X " }),
    f(function(_, snip)
      return { gen_str(snip.captures[1] - 2), "" }
    end),
    t(" | >{"),
    c(3, { t("\\centering"), t("\\raggedright"), t("\\raggedleft") }),
    t({ "\\arraybackslash}X | }", "" }),

    -- 制作表头第一个
    t({ "", "\\caption{" }),
    i(4, "table caption"),
    t({ "}\\\\", "" }),
    t({ "\\hline", "" }),
    d(5, function(_, parent)
      return gen_tab_1(parent.snippet.captures[1], 1)
    end, {}, { user_args = {} }),
    t({ "\\endfirsthead", "" }),
    -- 制作表头第二个
    t({ "", "\\caption{" }),
    i(6, "table caption"),
    t({ "}\\\\", "" }),
    t({ "\\hline", "" }),
    d(7, function(_, parent)
      return gen_tab_1(parent.snippet.captures[1], 1)
    end, {}, { user_args = {} }),
    -- 尾巴
    t({ "\\endhead", "" }),
    t({ "\\endfoot", "" }),
    t({ "\\endlastfoot", "", "" }),
    -- 编辑表格基本结构，默认为全中心
    t({ "\\hline", "" }),
    t({ "\\hline", "" }),
    d(8, function(_, parent)
      return gen_tab(parent.snippet.captures[1], parent.snippet.captures[2])
    end, {}, { user_args = {} }),
    t({ "", "\\end{xltabular}" }),
    i(0),
  }, {
    condition = tex.in_text,
  }),

  s({
    trig = [[ltab(%d+)s]],
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "pattern",
  }, {
    d(1, function(_, parent)
      return gen_tab_2(parent.captures[1], 1)
    end, {}, { user_args = {} }),
  }, {
    condition = tex.in_table,
  }),
  s({
    trig = "n_(%d+)s",
    snippetType = "autosnippet",
    wordTrig = true,
    trigEngine = "pattern",
  }, {
    d(1, function(_, parent)
      return gen_tab_2(parent.captures[1], 1)
    end, {}, { user_args = {} }),
  }, {
    condition = tex.in_table,
  }),
}
