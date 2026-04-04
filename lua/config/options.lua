local autocmd = vim.api.nvim_create_autocmd
-- @type "telescope" | "fzf" | "snacks"
vim.g.picker = "snacks"
vim.g.mini_file_opened = false
vim.g.hammerspoon = true
vim.o.splitkeep = "screen"
-- Disable global spell checking, will be enabled per filetype
vim.opt.spell = false
-- vim.opt.spelllang = "en_us"
-- vim.opt.spelllang = "cjk"

-- Set up spell checking only for tex and markdown files with English checking but ignoring CJK
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "tex", "markdown", "typst" },
  callback = function()
    if vim.bo.buftype ~= "nofile" then
      vim.opt_local.spell = true
      vim.opt_local.spelllang = "en_us,cjk"
    end
  end,
})
vim.opt.showmode = false
vim.o.tabstop = 2
vim.opt.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true

_G.mode = "error"
-- Enable break indent
vim.o.breakindent = true
vim.opt.undofile = true
vim.opt.number = true
vim.opt.relativenumber = true
-- 设置 statusline
vim.o.cmdheight = 1
vim.opt.updatetime = 1
vim.opt.clipboard = "unnamedplus"
vim.o.ttyfast = true
vim.o.lazyredraw = true
vim.opt.laststatus = 3
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.conceallevel = 2
vim.g.tex_conceal = "abdmg"
vim.diagnostic.config({
  virtual_text = true,
  virtual_lines = { current_line = true },
  underline = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
  },
})
vim.opt.foldmethod = "marker"
vim.opt.relativenumber = false
-- set WinSeparator to " "
vim.cmd([[highlight WinSeparator guifg=#181825]])
-- vim.g.codecompanion_enabled = true
vim.g.avante_enabled = false
vim.g.copilot_chat_enabled = true
vim.o.title = false
-- vim.opt.fillchars:append({ vert = "", eob = "" })
-- vim.opt.virtualedit = "all"
vim.o.statusline = "%f %m %r %h %w %= %y %p%% %l:%c"
vim.opt.matchpairs:append("$:$")

vim.g.rime_enabled = true
vim.g.dict_enabled = true -- dictionary 服务器默认 CMP 开启；on_attach 会将其关闭
vim.g.dict_initialized = false
vim.lsp.enable({ "dictionary", "rime_ls" })

local lsp_by_ft = {
  arduino = { "arduino" },
  astro = { "astro-ls" },
  c = { "clangd" },
  cpp = { "clangd" },
  html = { "html_lsp" },
  javascript = { "vtsls" },
  javascriptreact = { "vtsls" },
  lua = { "emmylua_ls" },
  markdown = { "harper_ls", "ltex" },
  objc = { "clangd" },
  objcpp = { "clangd" },
  python = { "pyright" },
  rust = { "rust_analyzer" },
  swift = { "sourcekit-lsp" },
  -- tex = { "harper_ls", "ltex", "texlab" },
  -- plaintex = { "harper_ls", "ltex", "texlab" },
  tex = { "ltex", "texlab" },
  plaintex = { "ltex", "texlab" },
  typst = { "harper_ls", "ltex", "tinymist", "zk-lsp" },
  typescript = { "vtsls" },
  typescriptreact = { "vtsls" },
  wolfram = { "wolfram_lsp" },
  xml = { "html_lsp" },
  yaml = { "ts_query_ls" },
}

local enabled_lsp = {}

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local servers = lsp_by_ft[args.match]
    if not servers then
      return
    end

    for _, server in ipairs(servers) do
      if not enabled_lsp[server] then
        vim.lsp.enable(server)
        enabled_lsp[server] = true
      end
    end
  end,
})

autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    if vim.bo.buftype == "nofile" then
      vim.opt_local.conceallevel = 2
      vim.opt_local.concealcursor = "nc"
    end
  end,
})

autocmd("BufWritePre", { pattern = { "*.md", "*.html" }, command = "set nowritebackup" })
autocmd("BufWritePost", { pattern = { "*.md", "*.html" }, command = "set writebackup" })

autocmd("OptionSet", {
  pattern = "diff",
  callback = function()
    vim.wo.wrap = true
  end,
})

vim.o.scrolloff = 5
vim.o.winborder = "none"

if vim.fn.has("linux") == 1 then
  vim.g.clipboard = {
    name = "orbstack-clipboard",
    copy = {
      ["+"] = { "pbcopy" },
      ["*"] = { "pbcopy" },
    },
    paste = {
      ["+"] = { "pbpaste" },
      ["*"] = { "pbpaste" },
    },
    cache_enabled = 1,
  }
  vim.o.clipboard = "unnamedplus"
end

vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
