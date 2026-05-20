local function find_git_root(filepath)
  local uv = vim.uv or vim.loop
  local dir = filepath ~= nil and filepath ~= "" and vim.fn.fnamemodify(filepath, ":p:h") or vim.fn.getcwd()
  while dir and dir ~= "/" do
    local stat = uv.fs_stat(dir .. "/.git")
    if stat and stat.type == "directory" then
      return dir
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

local wiki_root = vim.fs.normalize(vim.fn.expand("~/wiki"))
local wiki_concealer_context = vim.fs.normalize(vim.fn.expand("~/wiki/concealer-context.typ"))
local excluded_render_paths = {
  [vim.fs.normalize(vim.fn.expand("~/wiki/link.typ"))] = true,
  [vim.fs.normalize(vim.fn.expand("~/wiki/index.typ"))] = true,
}

local function is_wiki_path(path)
  if path == nil or path == "" then
    return false
  end
  path = vim.fs.normalize(path)
  return path == wiki_root or path:sub(1, #wiki_root + 1) == wiki_root .. "/"
end

return {
  {
    "dirichy/latex_concealer.nvim",
    enabled = false,
    dev = true,
    ft = { "tex", "latex" },
    opts = {},
  },
  {
    "ryleelyman/latex.nvim",
    ft = { "tex", "latex" },
    enabled = false,
    config = function()
      require("latex").setup({})
    end,
  },
  {
    "pxwg/math-conceal.nvim",
    event = "VeryLazy",
    build = "cargo build --release --manifest-path service/Cargo.toml",
    dev = vim.fn.has("mac") == 1,
    -- enabled = false,
    -- build = "make lua51",
    main = "math-conceal",
    opts = {
      ft = { "plaintex", "tex", "context", "bibtex", "typst", "markdown" },
      image = {
        enabled = true,
        filetypes = { "typst", "markdown", "latex" },
        markdown_filetypes = { "markdown", "copilot-chat" },
        service_binary = "/Users/pxwg-dogggie/math-conceal.nvim/service/target/release/typst-concealer-service",
        ppi = 300,
        math_baseline_pt = 11,
        styling_type = "colorscheme",
        color = nil,
        live_preview_debounce = 0,
        cursor_hover_throttle_ms = 0,
        header = [[
      // #show math.equation: set text(font: "Fira Math")
      #show math.equation.where(block: false): it => {
        set text(size: 0.85em)
        it
      }
    ]],
        get_root = function(_bufnr, path, cwd, _kind)
          if is_wiki_path(path) then
            return wiki_root
          end
          return find_git_root(path) or cwd
        end,
        get_inputs = function(_bufnr, path, _cwd, _kind)
          local id = vim.fn.fnamemodify(path, ":t:r")
          return {
            "focus=" .. id,
            "concealed=true",
            "preview=true",
            "preview-concealer=true",
          }
        end,
        get_preamble_file = function(_bufnr, path, _cwd, _kind)
          if is_wiki_path(path) then
            return wiki_concealer_context
          end
        end,
        render_paths = {
          exclude = {
            function(path)
              return excluded_render_paths[vim.fs.normalize(path)] == true
            end,
          },
        },
        conceal_in_normal = false,
        backends = {
          latex = {
            enabled = true,
            compiler = "pdflatex",
            converter = "pdftocairo",
          },
        },
      },
      enabled = true,
      highlights = { ["@sup_symbol"] = { link = "@boolean" } },
      conceal = {
        "greek",
        "script",
        "math",
        "font",
        "delim",
        "phy",
      },
    },
  },
}
