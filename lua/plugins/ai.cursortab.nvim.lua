local partial_accept_key = "<Plug>(CursorTabPartialAccept)"

return {
  "cursortab/cursortab.nvim",
  version = "v0.8.0",
  enabled = false,
  lazy = false,
  build = "cd server && go build",
  config = function()
    local inspect_url = require("util.cursortab_inspect").setup()

    require("cursortab").setup({
      keymaps = {
        accept = false,
        partial_accept = partial_accept_key,
        trigger = false,
      },
      behavior = {
        idle_completion_delay = 500,
        text_change_debounce = 500,
        ignore_filetypes = { "", "terminal", "make" },
      },
      provider = {
        type = "fim",
        url = inspect_url,
        completion_path = "/completions",
        api_key_env = "DEEPSEEK_API_KEY",
        model = "deepseek-v4-pro",
        max_tokens = 128,
        top_k = 0,
        completion_timeout = 10000,
      },
    })

    require("util.cursortab").register_partial_accept(partial_accept_key)
  end,
}
