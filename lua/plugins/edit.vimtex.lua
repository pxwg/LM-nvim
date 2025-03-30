return {
  {
    "lervag/vimtex",
    priority = 100,
    -- ft = { "latex", "markdown" },
    -- enable = false,
    config = function()
      vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
      vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
      vim.cmd([[
let g:tex_flavor='latex'
let g:vimtex_view_method = 'zathura'
"let g:vimtex_view_zathura_use_synctex = 0
" let g:vimtex_view_enabled = 0
let g:vimtex_quickfix_mode=0
let g:vimtex_fold_enabled=1
set conceallevel=2
"let g:tex_conceal="abdgm"
" 启用 conceal 功能
"set concealcursor=nc
let g:vimtex_view_method = 'zathura'
"let g:vimtex_view_general_options = '--synctex-forward @line:@col:@pdf @tex'

let g:vimtex_syntax_custom_cmds = [
      \ {'name': 'exp', 'cmdre': 'exp>', 'mathmode': 1, 'argstyle': 'bold', 'concealchar': 'E'},
      \ {'name': 'R', 'cmdre': 'R>', 'mathmode': 1, 'concealchar': 'ℝ'},
      \]
let g:vimtex_syntax_custom_cmds_with_concealed_delims = [
          \ {'name': 'ket',
          \  'mathmode': 1,
          \  'cchar_open': '|',
          \  'cchar_close': '>'},
          \ {'name': 'frac',
          \  'nargs': 2,
          \  'mathmode': 1,
          \  'cchar_open': '',
          \  'cchar_mid': '/',
          \  'cchar_close': ''},
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
          \ 'sections': 1,
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
  },
  {
    "ixru/nvim-markdown",
    -- event = "VeryLazy",
    enabled = false,
    config = function()
      vim.cmd([[let g:vim_markdown_math = 1]])
      vim.cmd([[let g:vim_markdown_conceal = 2]])
      vim.cmd([[let g:vim_markdown_no_default_key_mappings = 1]])
    end,
  },
}
