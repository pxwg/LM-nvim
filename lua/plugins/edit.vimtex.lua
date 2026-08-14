return {
  {
    "lervag/vimtex",
    priority = 100,
    -- ft = { "latex", "markdown" },
    -- enabled = false,
    init = function()
      vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
      vim.g.vimtex_quickfix_mode = 0
      -- vim.g.vimtex_compiler_silent = 1
      -- vim.g.vimtex_syntax_enabled = 1
      vim.g.vimtex_syntax_conceal_disable = 1
      vim.g.vimtex_view_method = "skim"
      vim.cmd([[
      let g:vimtex_view_sioyek_exe='sioyek'
      let g:vimtex_callback_progpath = '/opt/homebrew/opt/neovim/bin/nvim'
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
      vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventViewReverse",
        callback = function()
          vim.system({ "open", "/Applications/kitty.app" })
        end,
      })
    end,
  },
  { "let-def/texpresso.vim" },
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
