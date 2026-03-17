local function find_git_root(filepath)
  local uv = vim.loop
  local dir = vim.fn.fnamemodify(filepath, ":p:h")
  while dir and dir ~= "/" do
    local git_dir = dir .. "/.git"
    local stat = uv.fs_stat(git_dir)
    if stat and stat.type == "directory" then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return nil
end

return {
  "PartyWumpus/typst-concealer",
  -- enabled = false,
  dev = true,
  opts = {
    compiler_args = {
      "--root",
      find_git_root(vim.api.nvim_buf_get_name(0)) or vim.fn.getcwd(),
      "--input",
      "concealed=true",
      "--input",
      "preview-concealer=true",
    },
    header = [[
      // #show math.equation: set text(font: "Fira Math")
      #show math.equation.where(block: false): it => {
        set text(size: 0.85em)
        it
      }
    ]],
    render_paths = {
      exclude = {
        function(path)
          return path == vim.fs.normalize("~/wiki/link.typ") or path == vim.fs.normalize("~/wiki/index.typ")
        end,
      },
    },
  },
  ft = "typst",
}
