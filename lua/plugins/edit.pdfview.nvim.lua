return {
  {
    dir = vim.fn.expand("~/pdf.nvim"),
    name = "pdfview.nvim",
    lazy = false,
    build = "scripts/build-pdfviewd.sh",
    opts = {
      backend = "auto",
      keymaps = true,
      render = {
        enabled = true,
        auto = true,
        transport = "kitty-placeholder",
      },
      ui = {
        winbar = true,
        picker = "snacks",
      },
      integrations = {
        vimtex = {
          enabled = true,
          set_view_method = true,
        },
      },
      tools = {
        mutool = "mutool",
        magick = "magick",
        pdfviewd = vim.fn.expand("~/pdf.nvim/build/pdfviewd"),
        kitty = "kitty",
        synctex = "synctex",
      },
    },
    config = function(_, opts)
      require("pdfview").setup(opts)
    end,
  },
}
