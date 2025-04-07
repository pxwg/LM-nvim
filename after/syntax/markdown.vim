" Markdown math syntax highlighting
syn include @tex ~/.local/share/nvim/lazy/vimtex/syntax/tex.vim
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
