-- One default wiki; project-owned setup remains in the wiki repository.
local M = {}

function M.root()
  return vim.fs.normalize(vim.fn.expand(vim.g.wiki_root or "~/wiki-ocaml"))
end

-- Prefer the file's own knowledge project for completion previews.
function M.project(path)
  path = path or vim.api.nvim_buf_get_name(0)
  return (path ~= "" and vim.fs.root(path, ".zettypst")) or M.root()
end

function M.open()
  -- Use Neovim's cwd API so DirChanged and directory-scoped plugins are notified.
  vim.api.nvim_set_current_dir(M.root())
  Snacks.picker.files({ cwd = M.root() })
end

function M.setup()
  local root = M.root()
  vim.g.wiki_root = root
  -- The trusted local config may already have initialized this project.
  if not (_G.WikiOcamlProject and _G.WikiOcamlProject[root]) then
    dofile(root .. "/.zettypst/nvim/init.lua")
  else
    -- Lazy removes its command stubs before config; restore commands even when
    -- exrc initialized the project first, without restarting LSP or watchers.
    require("zettypst_ocaml.commands").setup()
    if require("zettypst_ocaml.config").options.capture then
      require("zettypst_ocaml.capture").setup()
    end
  end
  vim.api.nvim_create_user_command("Zet", function(args)
    vim.api.nvim_cmd({ cmd = "WikiZet", args = args.fargs }, {})
  end, {
    nargs = "+",
    force = true,
    complete = require("zettypst_ocaml.commands").complete,
    desc = "Default wiki operations",
  })
end

return M
