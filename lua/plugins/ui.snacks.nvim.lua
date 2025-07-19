return {
  "folke/snacks.nvim",
  event = "VeryLazy",
  opts = {
    profiler = {
      globals = LUA_FUNC,
    },
    bigfiles = {
      enabled = true,
      max_size = 1024 * 1024 * 10, -- 10MB
      line_length = 1000,
    },
    ---@class snacks.image.Config
    image = {
      -- enabled = false,
      math = {
        enabled = false,
        -- enabled = true,
        typst = {
          tpl = [[
        #set page(width: auto, height: auto, margin: (x: 5pt, y: 5pt))
        #show math.equation.where(block: false): set text(top-edge: "bounds", bottom-edge: "bounds")
        #set text(size: 10pt, fill: rgb("${color}"))
        ${header}
        ${content}]],
        },
      },
      doc = {
        -- Personally I set this to false, I don't want to render all the
        -- images in the file, only when I hover over them
        -- render the image inline in the buffer
        -- if your env doesn't support unicode placeholders, this will be disabled
        -- takes precedence over `opts.float` on supported terminals
        -- inline = vim.g.neovim_mode == "skitty" and true or false,
        -- only_render_image_at_cursor = vim.g.neovim_mode == "skitty" and false or true,
        -- render the image in a floating window
        -- only used if `opts.inline` is disabled
        float = false,
        inline = true,
        -- Sets the size of the image
        -- max_width = 60,
        -- max_width = vim.g.neovim_mode == "skitty" and 20 or 50,
        -- max_height = vim.g.neovim_mode == "skitty" and 10 or 40,
        -- max_height = 30,
        -- Apparently, all the images that you preview in neovim are converted
        -- to .png and they're cached, original image remains the same, but
        -- the preview you see is a png converted version of that image
        --
        -- Where are the cached images stored?
        -- This path is found in the docs
        -- :lua print(vim.fn.stdpath("cache") .. "/snacks/image")
        -- For me returns `~/.cache/neobean/snacks/image`
        -- Go 1 dir above and check `sudo du -sh ./* | sort -hr | head -n 5`
      },
    },
  },
}
