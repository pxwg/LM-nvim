return {
  "kkew3/jieba.vim",
  tag = "v1.0.5",
  event = "VeryLazy",
  build = "./build.sh",
  init = function()
    if vim.fn.has("linux") == 1 then
      vim.g.python3_host_prog = "/home/pxwg-dogggie/pyenv-nvim/bin/python3"
    end
    vim.g.jieba_vim_lazy = 1
    vim.g.jieba_vim_keymap = 0
  end,
  config = function()
    local motions = { "w", "W", "e", "E", "b", "B", "ge", "gE" }
    local objects = { "iw", "iW", "aw", "aW" }

    local function vim_string(value)
      return vim.fn.string(value)
    end

    local function nmap_rhs(motion)
      return ("<Cmd>call JiebaNmap(%s, v:count1, '')<CR>"):format(vim_string(motion))
    end

    local function xmap_rhs(motion)
      return ("<Cmd>call JiebaXmap(%s, v:count1, '')<CR>"):format(vim_string(motion))
    end

    local function omap_rhs(motion)
      return function()
        return ("<Esc><Cmd>call JiebaOmap(%s, 0, %d, %s, %s, '')<CR>"):format(
          vim_string(motion),
          vim.v.count1,
          vim_string(vim.v.operator),
          vim_string(vim.v.register)
        )
      end
    end

    for _, motion in ipairs(motions) do
      vim.keymap.set("n", motion, nmap_rhs(motion), { silent = true })
      vim.keymap.set("x", motion, xmap_rhs(motion), { silent = true })
      vim.keymap.set("o", motion, omap_rhs(motion), { expr = true, replace_keycodes = true, silent = true })
    end

    for _, object in ipairs(objects) do
      vim.keymap.set("x", object, xmap_rhs(object), { silent = true })
      vim.keymap.set("o", object, omap_rhs(object), { expr = true, replace_keycodes = true, silent = true })
    end
  end,
}
