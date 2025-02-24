return {
  "lervag/vimtex",
  priority = 100,
  config = function()
    vim.cmd([[
let g:tex_flavor='latex'
let g:vimtex_view_method = 'zathura'
"let g:vimtex_view_zathura_use_synctex = 0
" let g:vimtex_view_enabled = 0
let g:vimtex_quickfix_mode=0
let g:vimtex_fold_enabled=0
set conceallevel=2
let g:tex_conceal="abdgm"
" 启用 conceal 功能
set concealcursor=nc

" 为 Markdown 文件启用 vimtex 的 conceal 设置
autocmd FileType markdown setlocal conceallevel=2
autocmd FileType markdown setlocal concealcursor=nc

let g:vimtex_view_method = 'zathura'
"let g:vimtex_view_general_options = '--synctex-forward @line:@col:@pdf @tex'

let g:vimtex_syntax_custom_cmds_with_concealed_delims = [
          \ {'name': 'ket',
          \  'mathmode': 1,
          \  'cchar_open': '|',
          \  'cchar_close': '>'},
          \ {'name': 'binom',
          \  'nargs': 2,
          \  'mathmode': 1,
          \  'cchar_open': '(',
          \  'cchar_mid': '|',
          \  'cchar_close': ')'},
          \]
let g:vimtex_syntax_conceal = {
          \ 'accents': 1,
          \ 'ligatures': 1,
          \ 'cites': 1,
          \ 'fancy': 1,
          \ 'spacing': 1,
          \ 'greek': 1,
          \ 'math_bounds': 1,
          \ 'math_delimiters': 1,
          \ 'math_fracs': 1,
          \ 'math_super_sub': 1,
          \ 'math_symbols': 1,
          \ 'sections': 0,
          \ 'styles': 1,
          \}
]])
    vim.cmd([[
let g:vimtex_compiler_latexmk = {
        \ 'aux_dir' : '',
        \ 'out_dir' : '',
        \ 'callback' : 1,
        \ 'continuous' : 1,
        \ 'executable' : 'latexmk',
        \ 'hooks' : [],
        \ 'options' : [
        \   '-verbose',
        \   '-file-line-error',
        \   '-synctex=1',
        \   '-interaction=nonstopmode',
        \ ],
        \}
]])
  end,
}
