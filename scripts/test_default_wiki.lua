-- Read-only integration check with the real configuration:
-- cd /tmp && nvim --headless '+luafile ~/.config/nvim/scripts/test_default_wiki.lua'
local wiki = require("util.wiki")
local root = vim.fn.expand("~/wiki-ocaml")
assert(wiki.root() == root)
require("lazy").load({ plugins = { "wiki-ocaml" } })
assert(package.loaded.zettypst_ocaml, "OCaml plugin not loaded")
assert(not package.loaded.zettypst, "legacy plugin was loaded")
assert(vim.fn.exists(":Zet") == 2)
assert(vim.fn.exists(":WikiZet") == 2)
assert(vim.fn.exists(":WikiStatus") == 2)
local plugin = require("zettypst_ocaml")
assert(plugin.root_dir(0) == root, "default root missing outside wiki")
local pick = require("zettypst_ocaml.picker")
local captured
local original = pick.open
pick.open = function(index)
  captured = index
end
vim.cmd("Zet search")
pick.open = original
assert(captured and #captured.list > 700, "global search failed")
local before = vim.fn.getcwd()
local path = captured.list[1].origin.source
-- Probe actual file opening and the inherited project configuration, read-only.
vim.cmd.edit(vim.fn.fnameescape(path))
assert(plugin.root_dir(0) == root)
assert(vim.fn.exists(":Zet") == 2)
assert(vim.fn.getcwd() == before, "search/open changed cwd")
local options = require("zettypst_ocaml.config").options
assert(options.capture and options.actions.new)
local expected = options.root_dir("/tmp/unrelated-file.typ")
assert(expected == root)
-- Project reload must preserve the default fallback and command registration.
dofile(root .. "/.zettypst/nvim/init.lua")
assert(plugin.root_dir(vim.fn.bufadd("/tmp/unrelated-file.typ")) == root)
local lazy = require("lazy.core.config").plugins
assert(lazy["wiki-ocaml"] and not lazy["zettypst.nvim"])
local other = vim.fn.tempname()
vim.fn.mkdir(other .. "/.zettypst", "p")
assert(options.root_dir(other .. "/note.typ") == nil, "another project was redirected")
vim.fn.delete(other, "rf")
assert(
  vim.wait(15000, function()
    local clients = vim.lsp.get_clients({ bufnr = 0, name = "wiki-ocaml" })
    return clients[1] and clients[1].initialized
  end, 50),
  "wiki-ocaml failed to attach"
)
for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
  assert(client.name ~= "zettyp-lsp", "legacy semantic client attached")
end
print(
  "PASS default root, global search ("
    .. #captured.list
    .. " nodes), project opening/reload, no cwd change, no legacy plugin"
)
vim.cmd("qa!")
