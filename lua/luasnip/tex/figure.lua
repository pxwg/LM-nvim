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

return {
  s(
    { trig = "lfig", snippetType = "autosnippet" },
    { t("\\scaleral*{\\includegraphics{~/Desktop/physics/figure/"), i(1), t("}}{"), i(2, "B"), t("}") },
    { condition = tex.in_text }
  ),

  s({ trig = "infig", snippetType = "autosnippet" }, {
    c(1, {
            sn(
        nil,
        fmta(
          [[
            \begin{figure}[H]
              \centering
              \includegraphics[width = 0.8\textwidth]{./<>}
              \caption{<>}
              \label{<>}
            \end{figure}<>
            ]],
          { i(1), i(2), i(3), i(0) }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            \begin{figure}[H]
              \centering
              \includegraphics[width = 0.8\textwidth]{/Users/pxwg-dogggie/Desktop/physics/figure/<>}
              \caption{<>}
              \label{<>}
            \end{figure}<>
            ]],
          { i(1), i(2), i(3), i(0) }
        )
      ),
      sn(
        nil,
        fmta(
          [[
        \begin{figure}[b]
          \centering
          \includegraphics[width = 0.8\textwidth]{/Users/pxwg-dogggie/Desktop/physics/figure/<>}
          \caption{<>}
          \label{<>}
        \end{figure}<>
        ]],
          { i(1), i(2), i(3), i(0) }
        )
      ),
      sn(
        nil,
        fmta(
          [[
        \begin{figure}[H]
          \centering
          fig <> fig<>
          \caption{<>}
          \label{<>}
        \end{figure}<>
        ]],
          { i(3), i(4), i(1), i(2), i(0) }
        )
      ),
    }),
  }, { condition = tex.in_text }),
}
