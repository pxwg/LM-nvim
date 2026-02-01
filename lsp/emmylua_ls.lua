return {
  name = "emmylua_ls",
  cmd = { "emmylua_ls" },
  filetypes = { "lua" },
  root_dir = vim.fn.getcwd(),
  single_file_support = true,
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        requirePattern = {
          "lua/?.lua",
          "lua/?/init.lua",
        },
      },
      workspace = {
        library = vim.tbl_extend("force", {
          vim.env.VIMRUNTIME .. "/lua/",
          vim.fn.stdpath("config") .. "/lua",
          "${3rd}/luv/library",
          vim.fn.expand("HOME") .. "/.hammerspoon/Spoons/EmmyLua.spoon/annotations",
        }, vim.api.nvim_get_runtime_file("lua", true)),
      },
    },
  },
}
