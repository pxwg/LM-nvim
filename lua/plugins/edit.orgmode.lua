return {
  "nvim-orgmode/orgmode",
  event = "VeryLazy",
  -- Load before an org buffer is set up so its parser and injection
  -- directives exist when math-conceal parses Typst inside it.
  ft = { "org" },
  config = function()
    require("orgmode").setup({
      org_agenda_files = "~/orgfiles/**/*",
      org_default_notes_file = "~/orgfiles/refile.org",
      org_hide_emphasis_markers = true,
    })
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("OrgConceal", { clear = true }),
      pattern = "org",
      callback = function()
        vim.opt_local.conceallevel = 2
      end,
    })
    vim.lsp.enable("org")
  end,
}
