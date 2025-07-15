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

local function not_in_math()
  return not in_math()
end

-- Recursive list snippet helper
local rec_ls
rec_ls = function()
  return sn(nil, {
    c(1, {
      t({ "" }),
      sn(nil, { t({ "", "- " }), i(1), d(2, rec_ls, {}) }),
    }),
  })
end

return {
  -- Document template
  s(
    { trig = "newfile", snippetType = "autosnippet" },
    fmta(
      [[
#import "@preview/physica:0.9.3": *

#set page(
  paper: "a4",
  margin: (x: 1.8cm, y: 1.5cm),
)
#set text(
  font: "New Computer Modern",
  size: 12pt,
)
#set heading(numbering: "1.1")
#set math.equation(numbering: "(1)")

#show: rest => columns(1, rest)

#align(center, text(17pt)[
  *<>*
])
#align(center, text(15pt)[
  <>
])
#align(center, text(11pt)[
  <>
])

<>
      ]],
      {
        i(1, "Document Title"),
        i(2, "Author Name"),
        i(3, "Date"),
        i(0),
      }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- Basic document sections
  s(
    { trig = "sec", snippetType = "autosnippet" },
    fmta("= <><>", { i(1, "Section Title"), i(0) }),
    { condition = function() return in_typst() and line_begin() end }
  ),

  s(
    { trig = "ssec", snippetType = "autosnippet" },
    fmta("== <><>", { i(1, "Subsection Title"), i(0) }),
    { condition = function() return in_typst() and line_begin() end }
  ),

  s(
    { trig = "sssec", snippetType = "autosnippet" },
    fmta("=== <><>", { i(1, "Subsubsection Title"), i(0) }),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- Lists
  s(
    { trig = "item", snippetType = "autosnippet" },
    fmta(
      [[
- <>
<>]],
      { i(1), i(0) }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  s(
    { trig = "enum", snippetType = "autosnippet" },
    fmta(
      [[
+ <>
<>]],
      { i(1), i(0) }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- Recursive list
  s("list", {
    t({ "- " }),
    i(1),
    d(2, rec_ls, {}),
    i(0),
  }, { condition = function() return in_typst() and line_begin() end }),

  -- Figures
  s(
    { trig = "fig", snippetType = "autosnippet" },
    fmta(
      [[
#figure(
  image("<>", width: <>%),
  caption: [<>],
) <<label(<>)>><>
      ]],
      {
        i(1, "path/to/image.png"),
        i(2, "80"),
        i(3, "Caption"),
        i(4, "fig:"),
        i(0),
      }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- Tables
  s(
    { trig = "table", snippetType = "autosnippet" },
    fmta(
      [[
#figure(
  table(
    columns: <>,
    [<>], [<>],
    [<>], [<>],
  ),
  caption: [<>],
) <label(<>)><>
      ]],
      {
        i(1, "2"),
        i(2, "Header 1"),
        i(3, "Header 2"),
        i(4, "Row 1 Col 1"),
        i(5, "Row 1 Col 2"),
        i(6, "Table Caption"),
        i(7, "tab:"),
        i(0),
      }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- Code blocks
  s(
    { trig = "code", snippetType = "autosnippet" },
    fmta(
      [[
```<>
<>
```<>
      ]],
      {
        i(1, "python"),
        i(2, "# Your code here"),
        i(0),
      }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- Theorem-like environments
  s(
    { trig = "theorem", snippetType = "autosnippet" },
    fmta(
      [[
#theorem[<>][
  <>
]<>
      ]],
      {
        i(1, "Theorem Title"),
        i(2, "Theorem content"),
        i(0),
      }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  s(
    { trig = "proof", snippetType = "autosnippet" },
    fmta(
      [[
#proof[
  <>
]<>
      ]],
      {
        i(1, "Proof content"),
        i(0),
      }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  s(
    { trig = "definition", snippetType = "autosnippet" },
    fmta(
      [[
#definition[<>][
  <>
]<>
      ]],
      {
        i(1, "Definition Title"),
        i(2, "Definition content"),
        i(0),
      }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- References
  s(
    { trig = "ref", snippetType = "autosnippet" },
    fmta("@<><>", { i(1, "label"), i(0) }),
    { condition = in_typst }
  ),

  s(
    { trig = "label", snippetType = "autosnippet" },
    fmta("<label(<>)><>", { i(1, "label"), i(0) }),
    { condition = in_typst }
  ),

  -- Footnotes
  s(
    { trig = "footnote", snippetType = "autosnippet" },
    fmta("#footnote[<>]<>", { i(1, "Footnote text"), i(0) }),
    { condition = in_typst }
  ),

  -- Page breaks and spacing
  s(
    { trig = "pagebreak", snippetType = "autosnippet" },
    t("#pagebreak()"),
    { condition = function() return in_typst() and line_begin() end }
  ),

  s(
    { trig = "vspace", snippetType = "autosnippet" },
    fmta("#v(<>)<>", { i(1, "1em"), i(0) }),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- Alignment
  s(
    { trig = "center", snippetType = "autosnippet" },
    fmta(
      [[
#align(center)[
  <>
]<>
      ]],
      { i(1), i(0) }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  s(
    { trig = "right", snippetType = "autosnippet" },
    fmta(
      [[
#align(right)[
  <>
]<>
      ]],
      { i(1), i(0) }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- Bibliography
  s(
    { trig = "bib", snippetType = "autosnippet" },
    fmta("#bibliography(\"<>\")<>", { i(1, "references.bib"), i(0) }),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- Citations
  s(
    { trig = "cite", snippetType = "autosnippet" },
    fmta("@<><>", { i(1, "citation_key"), i(0) }),
    { condition = in_typst }
  ),

  -- Comments
  s(
    { trig = "//", snippetType = "autosnippet" },
    fmta("// <><>", { i(1, "Comment"), i(0) }),
    { condition = function() return in_typst() and line_begin() end }
  ),

  -- Block comments
  s(
    { trig = "/*", snippetType = "autosnippet" },
    fmta(
      [[
/* <>
   <> */
      ]],
      { i(1, "Comment"), i(0) }
    ),
    { condition = function() return in_typst() and line_begin() end }
  ),
}

