return {
  "ravitemer/mcphub.nvim",
  build = "npm install -g mcp-hub@latest",
  event = "VeryLazy",
  config = function()
    require("mcphub").setup({
      auto_start = false, -- automatically start MCP Hub on Neovim startup
      extensions = {
        avante = {
          make_slash_commands = true, -- make /slash commands from MCP server prompts
        },
      },
    })
  end,
}
