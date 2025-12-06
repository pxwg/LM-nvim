-- https://rozukke.dev/blog/astro-lsp-nvim/
local function get_tsserver_path(root_dir)
  local found = vim.fs.find("node_modules", { path = root_dir, upward = true, type = "directory" })[1]
  if found then
    local ts_lib = vim.fs.joinpath(vim.fs.dirname(found), "node_modules", "typescript", "lib")
    if vim.fn.isdirectory(ts_lib) == 1 then
      return ts_lib
    end
  end
  -- Fallback to global typescript if local not found
  local global_ts = vim.fn.systemlist("npm root -g")[1]
  if global_ts then
    local global_ts_lib = vim.fs.joinpath(global_ts, "typescript", "lib")
    if vim.fn.isdirectory(global_ts_lib) == 1 then
      return global_ts_lib
    end
  end
  return nil
end

return {
  cmd = {
    "astro-ls",
    "--stdio",
  },
  filetypes = {
    "astro",
    "ts",
  },
  root_markers = {
    "package.json",
    "tsconfig.json",
    "jsconfig.json",
    ".git",
  },
  init_options = {
    typescript = {
      tsdk = "",
    },
  },
  before_init = function(_, config)
    local tsdk = get_tsserver_path(config.root_dir)
    if tsdk then
      config.init_options.typescript.tsdk = tsdk
    end
  end,
}
