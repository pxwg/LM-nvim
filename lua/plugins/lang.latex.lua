-- LaTeX language support and tools
return {
  {
    "pxwg/latex.nvim",
    enabled = false,
    opts = {
      conceals = {
        enabled = {
          "greek",
          "math",
          "script", 
          "delim",
          "font",
        },
        add = {},
      },
      imaps = {
        enabled = false,
        add = {},
        default_leader = "`",
      },
      surrounds = {
        enabled = false,
        command = "c",
        environment = "e",
      },
    },
  },
  {
    "lervag/vimtex",
    priority = 10000000,
    init = function()
      vim.g.vimtex_mappings_disable = { ["n"] = { "K" } }
      vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
      vim.g.vimtex_compiler_silent = 1
      vim.g.vimtex_syntax_enabled = 1
      vim.g.vimtex_syntax_conceal_disable = 1
      vim.g.vimtex_view_method = "sioyek"
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
    "let-def/texpresso.vim",
    ft = "tex",
  },
  {
    "ixru/nvim-markdown",
    enabled = false,
    config = function()
      vim.cmd([[let g:vim_markdown_math = 1]])
      vim.cmd([[let g:vim_markdown_conceal = 2]])
      vim.cmd([[let g:vim_markdown_no_default_key_mappings = 1]])
    end,
  },
}