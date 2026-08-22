local focus = require("util.zk_tinymist_focus")
focus.setup()

local function pin_main(client, bufnr, main)
  local params = {
    command = "tinymist.pinMain",
    arguments = { main },
    title = "Pin main file",
  }
  client:request("workspace/executeCommand", params, function(err)
    if err then
      vim.schedule(function()
        vim.notify("Tinymist pinMain failed: " .. vim.inspect(err), vim.log.levels.WARN)
      end)
    end
  end, bufnr)
end

local function regular_main(bufnr, root)
  local main = root and vim.fs.joinpath(root, "index.typ") or nil
  if not main or vim.fn.filereadable(main) == 0 then
    main = vim.api.nvim_buf_get_name(bufnr)
  end
  return main
end

return {
  name = "tinymist",
  root_markers = {
    "tinymist.lock",
    ".gitignore",
    ".git",
    "typst.toml",
  },
  cmd = { "tinymist" },
  filetypes = { "typst" },
  capabilities = vim.lsp.protocol.make_client_capabilities(),
  settings = {
    tinymist = {
      projectResolution = "lockDatabase",
      invertColors = "auto",
      fontPaths = { "${workspaceFolder}/assets/fonts" },
    },
  },
  before_init = function(_, config)
    if vim.fs.normalize(config.root_dir or "") == focus.wiki_root() then
      config.settings.tinymist.projectResolution = "singleFile"
      config.settings.tinymist.typstExtraArgs = { "--input=zk-focus=true" }
    end
  end,
  on_attach = function(client, bufnr)
    -- The wiki keeps one stable main file. Its generated manifest selects only
    -- the active note and title-only stubs for that note's direct @ID links.
    if focus.note_id(bufnr) then
      focus.update(bufnr, nil, function(ok)
        if not vim.lsp.get_client_by_id(client.id) or not focus.is_active(bufnr) then
          return
        end
        pin_main(client, bufnr, ok and focus.focus_main() or vim.api.nvim_buf_get_name(bufnr))
      end)
      return
    end

    local root = client.root_dir
    if client.workspace_folders and client.workspace_folders[1] then
      root = client.workspace_folders[1].name
    end
    pin_main(client, bufnr, regular_main(bufnr, root))
  end,
}
