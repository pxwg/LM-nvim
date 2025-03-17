local M = {}
local function mkdMath()
  vim.cmd([[
      set foldmethod=marker
      syn include @tex /Users/pxwg-dogggie/.local/share/nvim/lazy/vimtex/syntax/tex.vim

syn region mkdMath
      \ start="\$" end="\$"
      \ skip="\\\$"
      \ containedin=@markdownTop
      \ contains=@tex
      \ keepend
      \ oneline

syn region mkdMath
      \ start="\$\$" end="\$\$"
      \ skip="\\\$"
      \ containedin=@markdownTop
      \ contains=@tex
      \ keepend

      syn match mkdTaskItem /\v^\s*-\s*\[\s*s*\]/
      highlight link mkdTaskItem RenderMarkdownTodo
      syn match mkdItemDash /^\s*-\s/
      highlight link mkdItemDash @markup.list
      syn match mkdTaskItem /\v^\s*-\s*\[\s*[x]\s*\]/
      highlight link mkdTaskItem RenderMarkdownTodo
      syn match mkdItemDot /^\s*\*/
      highlight link mkdItemDot @markup.list
      syn match markdownCodeDelimiter /^```\w*/ conceal
      syn match markdownCodeDelimiter /^```$/ conceal

      syn match markdownH1 "^# .*$"
      syn match markdownH2 "^## .*$"
      syn match markdownH3 "^### .*$"
      syn match markdownH4 "^#### .*$"
      syn match markdownH5 "^##### .*$"
      syn match markdownH6 "^###### .*$"

      " Link syntax to highlight groups
      highlight link markdownH1 rainbow1
      highlight link markdownH2 rainbow2
      highlight link markdownH3 rainbow3
      highlight link markdownH4 rainbow4
      highlight link markdownH5 rainbow5
      highlight link markdownH6 rainbow6

    ]])
end
M.mkdMath = mkdMath
return M
