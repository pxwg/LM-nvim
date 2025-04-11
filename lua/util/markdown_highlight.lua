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
        enabled = { "font", "math", "greek", "script" },
      })
      vim.cmd("e")
    end,
  })
end

-- 映射表：\mathbb{X} 到 Unicode 字符
local mathbb_map = {
  A = "𝔸",
  B = "𝔹",
  C = "ℂ",
  D = "𝔻",
  E = "𝔼",
  F = "𝔽",
  G = "𝔾",
  H = "ℍ",
  I = "𝕀",
  J = "𝕁",
  K = "𝕂",
  L = "𝕃",
  M = "𝕄",
  N = "ℕ",
  O = "𝕆",
  P = "ℙ",
  Q = "ℚ",
  R = "ℝ",
  S = "𝕊",
  T = "𝕋",
  U = "𝕌",
  V = "𝕍",
  W = "𝕎",
  X = "𝕏",
  Y = "𝕐",
  Z = "ℤ",
}

-- 注册 conceal callback
function M.set_bb()
  vim.treesitter.query.set(
    "latex",
    "highlights",
    [[
  ((generic_command) @mathbb_symbol
   (#match? @mathbb_symbol "\\\\mathbb\\{([A-Z])\\}"))
  ]]
  )

  -- 动态设置 conceal
  vim.api.nvim_set_hl(0, "Conceal", { default = true })
  -- Create a namespace for markdown math concealing
  local markdown_math_ns = vim.api.nvim_create_namespace("markdown_math_conceal")

  vim.api.nvim_create_autocmd("CursorMoved", {
    pattern = "*.md",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local parser = vim.treesitter.get_parser(bufnr, "latex")
      if not parser then
        return
      end

      local trees = parser:parse()
      if not trees or #trees == 0 then
        return
      end

      local root = trees[1]:root()
      if not root then
        return
      end

      -- Iterate through children properly using the iterator function
      for node in root:iter_children() do
        if node then
          local text = vim.treesitter.get_node_text(node, bufnr)
          if text then
            local match = text:match("\\mathbb%{([A-Z])%}")
            if match and mathbb_map[match] then
              vim.api.nvim_buf_set_extmark(bufnr, markdown_math_ns, node:start(), node:end_(), {
                conceal = mathbb_map[match],
              })
            end
          end
        end
      end
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
  local node = match[predicate[2]]
  for _ = 1, 2 do
    if not node then
      return false
    end
    node = node:parent()
  end
  if not node then
    return false
  end
  local ancestor_types = { unpack(predicate, 3) }
  if vim.tbl_contains(ancestor_types, node:type()) then
    return true
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

function M.get_mathfont_conceal(text)
  return font_tab[text] or ""
end

return M
