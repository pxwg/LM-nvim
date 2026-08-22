local function setup_features()
  require("config.mini").setup()
end

local function has_directory_arg()
  for _, arg in ipairs(vim.fn.argv()) do
    if vim.fn.isdirectory(vim.fn.fnamemodify(arg, ":p")) == 1 then
      return true
    end
  end
  return false
end

return {
  "echasnovski/mini.nvim",
  version = false,
  event = "VeryLazy",
  keys = {
    {
      "<leader>e",
      function()
        require("config.mini").toggle_files(false)
      end,
      desc = "Open mini.files (Directory of Current File)",
    },
    {
      "<leader>E",
      function()
        require("config.mini").toggle_files(true)
      end,
      desc = "Open mini.files (cwd)",
    },
  },
  config = function()
    if has_directory_arg() then
      require("config.mini").setup_files()
    end

    if #vim.api.nvim_list_uis() == 0 then
      setup_features()
      return
    end

    if vim.g.did_very_lazy then
      vim.schedule(setup_features)
      return
    end

    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("MiniFeatureSetup", { clear = true }),
      pattern = "VeryLazy",
      once = true,
      callback = setup_features,
      desc = "Initialize Mini features after the first UI frame",
    })
  end,
}
