-- math-conceal.nvim: Unicode conceal plus rendered Typst and Markdown math.

local service_binary = vim.fn.expand("~/math-conceal.nvim/service/target/release/typst-concealer-service")

local wiki_root = vim.fs.normalize(vim.fn.expand("~/wiki"))
local wiki_unrendered = {
  [wiki_root .. "/link.typ"] = true,
  [wiki_root .. "/index.typ"] = true,
}

local typst_header = [[
  #show math.equation: set text(font: "Pennstander Math", weight: 300)
  #show math.equation.where(block: false): set text(weight: 400)
  #show math.equation.where(block: false): it => {
    set text(size: 0.85em)
    it
  }
]]

local mitex_preamble = [[
\newcommand{\slashed}[1]{\not{#1}}
]]

local code_render_allow = {
  "show-tags",
  "zk_output_focused",
  "definition",
  "example",
  "fact",
  "problem",
  "proof",
  "proposition",
  "remark",
  "theorem",
  "footnote",
  "status_tag",
  "tag.idea",
  "tag.archived",
  "tag.legacy",
  "tag.sync",
  "tag.zk",
  "tag.neovim",
  "tag.typst",
  "tag.coding",
  "tag.physics",
  "tag.algebra",
  "tag.math",
  "tag.qft",
  "tag.classical-mechanics",
  "tag.quantum-mechanics",
  "tag.voa",
  "tag.rep-theory",
  "tag.topology",
  "tag.geometry",
  "tag.thinking",
  "tag.root",
  "tag.ag",
  "tag.by-ai",
  "tag.life",
  "tag.capture",
  "tag.yau-contest",
  "tag.animate",
  "retraction",
  "include-note",
}

local function in_wiki(path)
  path = vim.fs.normalize(path)
  return path == wiki_root or vim.startswith(path, wiki_root .. "/")
end

-- Opt in only projects providing the same native-focus rendering contract.
local function zettypst_root(path)
  -- Virtual buffer URIs may be normalized from :// to :/; neither is a project file.
  if path == "" or path:match("^%a[%w+.-]*:/") then
    return
  end
  local root = vim.fs.root(path, ".zettypst")
  if root and vim.uv.fs_stat(root .. "/concealer-context.typ") and vim.uv.fs_stat(root .. "/.zettypst/focus.typ") then
    return root
  end
end

local function render_root(ctx)
  return zettypst_root(ctx.path)
    or (in_wiki(ctx.path) and wiki_root)
    or vim.fs.root(ctx.path ~= "" and ctx.path or ctx.cwd, ".git")
    or ctx.cwd
end

local function render_inputs(ctx)
  return {
    "focus=" .. vim.fn.fnamemodify(ctx.path, ":t:r"),
    "concealed=true",
    "preview=true",
    "preview-concealer=true",
    "colored=false",
  }
end

local function render_preamble(ctx)
  local root = zettypst_root(ctx.path)
  if root then
    return root .. "/concealer-context.typ"
  end
  if in_wiki(ctx.path) then
    return wiki_root .. "/concealer-context.typ"
  end
end

local function render_excluded(ctx)
  if zettypst_root(ctx.path) then
    -- Focus rendering requires a note filename, not an aggregate/helper entry.
    return require("util.zettypst_focus").note(ctx.path) == nil
  end
  return wiki_unrendered[vim.fs.normalize(ctx.path)] == true
end

-- Every renderer compiles in the same project context.
local function project_renderer(spec)
  return vim.tbl_extend("force", {
    service_binary = service_binary,
    header = typst_header,
    root = render_root,
    inputs = render_inputs,
    preamble_file = render_preamble,
    render_paths = { exclude = { render_excluded } },
  }, spec)
end

return {
  "pxwg/math-conceal.nvim",
  dev = vim.fn.has("mac") == 1,
  event = "VeryLazy",
  main = "math-conceal",
  build = "cargo build --release --manifest-path service/Cargo.toml",
  opts = {
    -- `ft` is not appended to the plugin default: keep the full list.
    ft = {
      "plaintex",
      "tex",
      "context",
      "bibtex",
      "typst",
      "markdown",
      "coact",
      "coact-history",
      "coact-input",
    },
    opt = { concealcursor = "nci" },
    highlights = { ["@sup_symbol"] = { link = "@boolean" } },
    image = {
      enabled = true,
      workspace_dir = function(bufnr)
        local path = vim.api.nvim_buf_get_name(bufnr)
        local root = zettypst_root(path) or (in_wiki(path) and wiki_root)
        if root then
          return root .. "/.math-conceal.image"
        end
      end,
      renderers = {
        typst = project_renderer({
          code_render = { allow = code_render_allow },
        }),
        markdown = project_renderer({
          filetypes = { "markdown", "copilot-chat", "coact", "coact-history" },
          mitex_preamble = mitex_preamble,
        }),
      },
    },
  },
}
