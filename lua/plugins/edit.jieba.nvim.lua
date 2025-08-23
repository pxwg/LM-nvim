return {
  "kkew3/jieba.vim",
  tag = "v1.0.5",
  event = "VeryLazy",
  build = "./build.sh",
  init = function()
    vim.g.python3_host_prog = "/home/pxwg-dogggie/pyenv-nvim/bin/python3"
    vim.g.jieba_vim_lazy = 1
    vim.g.jieba_vim_keymap = 1
  end,
}
