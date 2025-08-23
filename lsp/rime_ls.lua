local rime_ls_filetypes =
  { "vimwiki", "tex", "markdown", "copilot-chat", "AvanteInput", "codecompanion", "typst", "hello" }

local rime_on_attach = function(client, _)
  local toggle_rime = function()
    client.request("workspace/executeCommand", { command = "rime-ls.toggle-rime" }, function(_, result, ctx, _)
      if ctx.client_id == client.id then
        vim.g.rime_enabled = result
      end
    end)
  end
  -- keymaps for executing command
  vim.keymap.set("n", "<leader>rr", toggle_rime, { desc = "Toggle [R]ime" })
  -- vim.keymap.set("i", "jn", toggle_rime, { desc = "Toggle Rime" })
  vim.keymap.set("n", "<leader>rs", function()
    vim.lsp.buf.execute_command({ command = "rime-ls.sync-user-data" })
  end, { desc = "[R]ime [S]ync" })
  -- vim.keymap.set("i", "jn", function()
  --   require("lsp.rime_ls").toggle_rime()
  --   _G.rime_toggled = not _G.rime_toggled
  --   _G.rime_ls_active = not _G.rime_ls_active
  -- end, { noremap = true, silent = true, desc = "toggle rime-ls" })
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
-- capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
capabilities.general.positionEncodings = { "utf-8" }

local function get_data_dir()
  local sys_name = vim.loop.os_uname().sysname
  if sys_name == "Darwin" then
    return "/Library/Input Methods/Squirrel.app/Contents/SharedSupport"
  elseif sys_name == "Linux" then
    return vim.fn.expand("~/.local/state/rime/")
  elseif sys_name == "Windows_NT" then
    return vim.fn.expand("C:/ProgramData/Rime/")
  else
    error("Unsupported OS: " .. sys_name)
    return ""
  end
end

local function get_user_data_dir()
  local sys_name = vim.loop.os_uname().sysname
  if sys_name == "Darwin" then
    return vim.fn.expand("~/Library/Rime_2/")
  elseif sys_name == "Linux" then
    return vim.fn.expand("~/.local/share/rime/")
  elseif sys_name == "Windows_NT" then
    return vim.fn.expand("C:/Users/" .. vim.fn.expand("$USER") .. "/AppData/Roaming/Rime/")
  else
    error("Unsupported OS: " .. sys_name)
    return ""
  end
end

return {
  name = "rime_ls",
  -- cmd = vim.lsp.rpc.connect("127.0.0.1", 9257),
  cmd = { vim.fn.expand("~/rime-ls/target/release/rime_ls") },
  filetypes = rime_ls_filetypes,
  single_file_support = true,
  init_options = {
    enabled = vim.g.rime_enabled,
    shared_data_dir = get_data_dir(),
    user_data_dir = get_user_data_dir(),
    log_dir = vim.fn.expand("~/.local/share/rime-ls-1/"),
    paging_characters = { ",", "." },
    trigger_characters = {},
    schema_trigger_character = "&",
    always_incomplete = false,
    preselect_first = false,
    show_filter_text_in_label = false,
    max_candidates = 9,
    max_tokens = 0,
    long_filter_text = true,
    -- long_filter_text = false,
  },
  -- on_attach = attach_in_insert_mode,
  on_attach = rime_on_attach,
  capabilities = capabilities,
}
