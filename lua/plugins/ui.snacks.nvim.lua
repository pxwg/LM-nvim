return {
  "folke/snacks.nvim",
  event = "VeryLazy",
  opts = {
    profiler = { enabled = true },
    bigfiles = {
      enabled = true,
      max_size = 1024 * 1024 * 10, -- 10MB
      line_length = 1000,
    },
    input = {
      -- enabled = false,
      enabled = true,
      -- This is the default, but I set it to false because I don't want
      -- the input to be rendered in a floating window, I want it to be
      -- rendered inline in the buffer
    },
    picker = { enabled = true },
    ---@class snacks.image.Config
    image = {
      -- enabled = false,
      math = {
        enabled = false,
        -- enabled = true,
        typst = {
          tpl = [[
        #set page(width: auto, height: auto, margin: (x: 5pt, y: 5pt))
        #let sym = "Sym"
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
        enabled = false,
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
  keys = {
    { "<leader>,", function() Snacks.picker.buffers() end, desc = "Switch Buffer" },
    {
      "<leader>/",
      function() Snacks.picker.grep({ cwd = require("util.cwd_attach").cwd() }) end,
      desc = "[G]rep (Root Dir)",
    },
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
    {
      "<leader><space>",
      function() Snacks.picker.files({ cwd = require("util.cwd_attach").cwd() }) end,
      desc = "Find Files (cwd)",
    },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "[B]uffers" },
    {
      "<leader>fc",
      function() Snacks.picker.files({ cwd = "~/.config/nvim" }) end,
      desc = "Find [C]onfig File",
    },
    {
      "<leader>ff",
      function() Snacks.picker.files({ cwd = require("util.cwd_attach").cwd() }) end,
      desc = "Find [F]iles (cwd)",
    },
    { "<leader>fF", function() Snacks.picker.files() end, desc = "Find [F]iles (Root Dir)" },
    { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find [G]it Files" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "[R]ecent" },
    {
      "<leader>fR",
      function() Snacks.picker.recent({ filter = { cwd = true } }) end,
      desc = "[R]ecent (cwd)",
    },
    { "<leader>gc", function() Snacks.picker.git_log() end, desc = "Git [C]ommits" },
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git [S]tatus" },
    { "<leader>sf", function() Snacks.picker.lines() end, desc = "[F]uzzy Find in Buffer" },
    { "<leader>sd", function() Snacks.picker.diagnostics_buffer() end, desc = "[D]iagnostics (Buffer)" },
    { "<leader>sD", function() Snacks.picker.diagnostics() end, desc = "Workspace [D]iagnostics" },
    {
      "<leader>sg",
      function() Snacks.picker.grep({ cwd = vim.fn.expand("%:p:h") }) end,
      desc = "[G]rep (cwd)",
    },
    { "<leader>sG", function() Snacks.picker.grep() end, desc = "[G]rep (Root Dir)" },
    { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Search [H]ighlight Groups" },
    { "<leader>sj", function() Snacks.picker.jumps() end, desc = "[J]umplist" },
    { "<leader>so", function() Snacks.picker.vim_options() end, desc = "[O]ptions" },
    { "<leader>ss", function() Snacks.picker.grep_word() end, desc = "[S]tring (Root Dir)" },
    {
      "<leader>sS",
      function() Snacks.picker.grep_word({ cwd = vim.fn.expand("%:p:h") }) end,
      desc = "[S]tring (cwd)",
    },
    { "<leader>ss", function() Snacks.picker.grep_word() end, mode = "v", desc = "[S]election (Root Dir)" },
    {
      "<leader>sS",
      function() Snacks.picker.grep_word({ cwd = vim.fn.expand("%:p:h") }) end,
      mode = "v",
      desc = "[S]election (cwd)",
    },
    { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "[C]olorscheme with Preview" },
  },
}
