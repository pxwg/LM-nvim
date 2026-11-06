local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local line_begin = require("luasnip.extras.expand_conditions").line_begin
local function document_line(line_to_cursor, matched_trigger, captures)
  return vim.bo.filetype == "typst" and line_begin(line_to_cursor, matched_trigger, captures)
end

return {
  s(
    { trig = "zkmeta", snippetType = "autosnippet" },
    fmt(
      [[
/* Metadata:
Aliases: {}
Abstract: {}
Keyword: {}
*/
]],
      {
        i(1),
        i(2),
        i(3),
      }
    ),
    { condition = document_line }
  ),
  s(
    { trig = "newfile", snippetType = "autosnippet" },
    fmt(
      [[
#import "@preview/physica:0.9.5": *
#import "@preview/commute:0.3.0": arr, commutative-diagram, node
#import "../preamble.typ": (
   color_scheme, conf, definition, example, proof, proposition,
  remark, theorem,
)
#show: color_scheme

//----------------------basic info ----------------------//

#let title = "{}"
#let author = "{}"
#let date = "{}"
#let year = "{}"

#show: doc => conf(
  title: title,
  author: author,
  date: date,
  year: year,
  textsize: 10pt,
  doc,
)

//-----------------------symbols----------------------//

#let sym = "Sym"

//---------------------main project---------------------//


      ]],
      {
        i(1),
        i(2),
        i(3),
        i(4),
      }
    ),
    { condition = document_line }
  ),
}
