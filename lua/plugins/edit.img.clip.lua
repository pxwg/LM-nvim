return {
  -- support for image pasting
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<C-v>",
      function()
        require("img-clip").paste_image()
      end,
      mode = "i",
      desc = "Paste image from clipboard",
    },
  },
  opts = {
    -- recommended settings
    filetypes = {
      ["copilot-chat"] = {
        prompt_for_file_name = false,
        template = "#image:`$FILE_PATH`",
        use_absolute_path = true,
        url_encode_path = false,
      },
      codecompanion = {
        prompt_for_file_name = false,
        template = "[Image]($FILE_PATH)",
        use_absolute_path = true,
      },
      ["coact-input"] = {
        dir_path = function()
          return vim.fs.joinpath(vim.fn.stdpath("data"), "img-clip", "coact-input")
        end,
        prompt_for_file_name = false,
        template = "@image:`$FILE_PATH`",
        use_absolute_path = true,
        url_encode_path = false,
      },
    },
    default = {
      embed_image_as_base64 = false,
      prompt_for_file_name = false,
      drag_and_drop = {
        insert_mode = true,
      },

      -- required for Windows users
      use_absolute_path = true,
    },
  },
}
