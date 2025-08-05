local M = {}
local function mkdMath()
  vim.cmd([[
      set foldmethod=marker
      syn include @tex /Users/pxwg-dogggie/.local/share/nvim/lazy/vimtex/syntax/tex.vim

syn region mkdMath
      \ start="\$" end="\$"
      \ skip="\\\$"
      \ containedin=@markdownTop
      \ contains=@tex
      \ keepend
      \ oneline

syn region mkdMath
      \ start="\$\$" end="\$\$"
      \ skip="\\\$"
      \ containedin=@markdownTop
      \ contains=@tex
      \ keepend

      syn match mkdTaskItem /\v^\s*-\s*\[\s*s*\]/
      highlight link mkdTaskItem RenderMarkdownTodo
      syn match mkdItemDash /^\s*-\s/
      highlight link mkdItemDash @markup.list
      syn match mkdTaskItem /\v^\s*-\s*\[\s*[x]\s*\]/
      highlight link mkdTaskItem RenderMarkdownTodo
      syn match mkdItemDot /^\s*\*/
      highlight link mkdItemDot @markup.list
      syn match markdownCodeDelimiter /^```\w*/ conceal
      syn match markdownCodeDelimiter /^```$/ conceal

      syn match markdownH1 "^# .*$"
      syn match markdownH2 "^## .*$"
      syn match markdownH3 "^### .*$"
      syn match markdownH4 "^#### .*$"
      syn match markdownH5 "^##### .*$"
      syn match markdownH6 "^###### .*$"

      " Link syntax to highlight groups
      highlight link markdownH1 rainbow1
      highlight link markdownH2 rainbow2
      highlight link markdownH3 rainbow3
      highlight link markdownH4 rainbow4
      highlight link markdownH5 rainbow5
      highlight link markdownH6 rainbow6

    ]])
end
M.mkdMath = mkdMath

function M.get_md_hl()
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = { "*.md", "*.tex" },
    once = true,
    callback = function()
      M.load_queries({
        enabled = { "font", "math", "greek", "script", "delim" },
      })
      vim.cmd("e")
    end,
  })
end

local function read_query_files(filenames)
  local contents = ""

  for _, filename in ipairs(filenames) do
    local file, err = io.open(filename, "r")
    local payload = ""
    if file then
      payload = file:read("*a")
      io.close(file)
    else
      error(err)
    end
    contents = contents .. "\n" .. payload
  end
  return contents
end

local function hasgrandparent(match, _, _, predicate)
  local nodes = match[predicate[2]]
  if not nodes or #nodes == 0 then
    return false
  end
  for _, node in ipairs(nodes) do
    local current = node
    local valid = true
    for _ = 1, 2 do
      current = current and current:parent()
      if not current then
        valid = false
        break
      end
    end
    if valid then
      local ancestor_types = { unpack(predicate, 3) }
      if vim.tbl_contains(ancestor_types, current:type()) then
        return true
      end
    end
  end

  return false
end

local function setpairs(match, _, source, predicate, metadata)
  -- (#set-pairs! @aa key list)
  local capture_id = predicate[2]
  local node = match[capture_id]
  local key = predicate[3]
  if not node then
    return
  end
  local node_text = vim.treesitter.get_node_text(node, source)
  for i = 4, #predicate, 2 do
    if node_text == predicate[i] then
      metadata[key] = predicate[i + 1]
      break
    end
  end
end

local function lua_func(match, _, source, predicate, metadata)
  -- (#lua_func! @capture key value)
  local capture_id = predicate[2]
  local node = match[capture_id]
  -- Exit early if node is nil
  if not node then
    return
  end
  -- Get the node text (for possible future use)
  local node_text = vim.treesitter.get_node_text(node, source)
  local key = predicate[3] or "conceal"
  local value = predicate[4] or "font"
  if type(metadata[capture_id]) ~= "table" then
    metadata[capture_id] = {}
  end
  metadata[capture_id][key] = M.get_mathfont_conceal(node_text)
end

--- @class QueryArgs
--- @field enabled string[] List of query names to load
local function load_queries(args)
  vim.treesitter.query.add_predicate("has-grandparent?", hasgrandparent, { force = true })
  vim.treesitter.query.add_directive("set-pairs!", setpairs, { force = true })
  vim.treesitter.query.add_directive("lua_func!", lua_func, { force = true })
  local out = vim.treesitter.query.get_files("latex", "highlights")
  -- local out = {}
  for _, name in ipairs(args.enabled) do
    local files = vim.api.nvim_get_runtime_file("queries_config/latex/conceal_" .. name .. ".scm", true)
    for _, file in ipairs(files) do
      table.insert(out, file)
    end
  end
  local strings = read_query_files(out)
  vim.treesitter.query.set("latex", "highlights", strings)
end

M.load_queries = load_queries

local font_tab = require("conceal.font_tables").math_font_table

function M.get_mathfont_conceal(param)
  local out = require("utils.latex_conceal").lookup_math_symbol(param)
  return out or text
end

return M
