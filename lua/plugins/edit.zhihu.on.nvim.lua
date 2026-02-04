local function get_commutative_diagram_ranges(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "typst")
  if not ok or not parser then
    return {}
  end
  local trees = parser:parse()
  if not trees or #trees == 0 then
    return {}
  end
  local root = trees[1]:root()
  local query_str = [[
    (call
      item: (ident) @cmd
      (#match? @cmd "commutative-diagram|equation-frame")
      (#not-has-ancestor? @cmd let)) @call
  ]]
  local query = vim.treesitter.query.parse("typst", query_str)
  local ranges = {}
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    if query.captures[id] == "call" then
      local start_row, _, end_row, _ = node:range()
      table.insert(ranges, { start_line = start_row + 1, end_line = end_row + 1 })
    end
  end
  return ranges
end

local function replace_commutative_diagrams_with_images(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local ranges = get_commutative_diagram_ranges(bufnr)
  if #ranges == 0 then
    return table.concat(lines, "\n")
  end

  local figs_dir = vim.fn.expand("~/figs")
  vim.fn.mkdir(figs_dir, "p")

  local template = [[
#import "@preview/physica:0.9.5": *
#import "@preview/commute:0.3.0": arr, commutative-diagram, node
#import "@preview/cetz:0.4.2": canvas, draw
#set page(width: auto, height: auto, margin: 0cm)
#let CS = math.upright("CS")
#let wedge = math.and
#let GL = math.upright("GL")
#let Conf = math.upright("Conf")
#let Hol = math.upright("Hol")
#let string-diagram(top-conn, bottom-conn, color: color) = {
  let x = (0, 4, 8); let y = (3, 9); let height = 12
  let hline(conn, y-level) = {
    let (x1, x2) = if conn == "12" { (x.at(0), x.at(1)) } else if conn == "13" { (x.at(0), x.at(2)) } else { (x.at(1), x.at(2)) }
    draw.line((x1, y-level), (x2, y-level), stroke: color)
    draw.circle((x1, y-level), radius: 0.6, stroke: color)
    draw.circle((x2, y-level), radius: 0.6, stroke: color)
  }
  canvas(length: 2pt, {
    for i in (0, 1, 2) { draw.line((x.at(i), 0), (x.at(i), height), stroke: color) }
    hline(top-conn, y.at(1)); hline(bottom-conn, y.at(0))
  })
}
#let equation-frame(content) = { if type(content) == function { content(string-diagram.with(color: black)) } else { content } }
%s
]]

  table.sort(ranges, function(a, b)
    return a.start_line > b.start_line
  end)
  local result_lines = vim.list_extend({}, lines)
  for i, range in ipairs(ranges) do
    local diagram_lines = {}
    for line_num = range.start_line, range.end_line do
      table.insert(diagram_lines, lines[line_num])
    end
    local diagram_content = table.concat(diagram_lines, "\n")
    local temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
    local typst_file = temp_dir .. "/diagram.typ"
    local pdf_file = temp_dir .. "/diagram.pdf"
    -- 使用时间戳防止覆盖
    local png_file = figs_dir .. "/diagram_" .. os.time() .. "_" .. i .. ".png"

    local typst_content = string.format(template, diagram_content)
    local file = io.open(typst_file, "w")
    if file then
      file:write(typst_content)
      file:close()
    else
      vim.notify("Failed to create Typst file", vim.log.levels.ERROR)
      goto continue
    end

    local compile_cmd = string.format("typst compile '%s' '%s'", typst_file, pdf_file)
    if vim.fn.system(compile_cmd) ~= "" and vim.v.shell_error ~= 0 then
      vim.notify("Typst compilation failed", vim.log.levels.ERROR)
      goto continue
    end

    local convert_cmd = string.format(
      "convert -density 300 '%s' -background white -alpha remove -alpha off -quality 90 '%s'",
      pdf_file,
      png_file
    )
    if vim.fn.system(convert_cmd) ~= "" and vim.v.shell_error ~= 0 then
      vim.notify("PDF to PNG conversion failed", vim.log.levels.ERROR)
      goto continue
    end

    local image_ref = string.format('#image("%s")', png_file)
    for line_idx = range.end_line, range.start_line, -1 do
      table.remove(result_lines, line_idx)
    end
    table.insert(result_lines, range.start_line, image_ref)
    vim.fn.delete(temp_dir, "rf")
    ::continue::
  end
  return table.concat(result_lines, "\n")
end

local function get_typst_title(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "typst")
  if not ok or not parser then
    return nil
  end
  local tree = parser:parse()[1]
  if not tree then
    return nil
  end
  local query_str = [[ (let pattern: (ident) @cmd (#eq? @cmd "title") value: (string) @title) ]]
  local query = vim.treesitter.query.parse("typst", query_str)
  for id, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
    if query.captures[id] == "title" then
      local text = vim.treesitter.get_node_text(node, bufnr)
      return text:match('^"(.*)"$') or text
    end
  end
  return nil
end

local function write_content_to_tempfile_and_return_path(content_string, orig_path, ft)
  ft = ft or ".typ"
  local dir = vim.fn.fnamemodify(orig_path, ":h")
  local filename = "converted_content_" .. tostring(os.time()) .. ft
  local full_path = dir .. "/" .. filename
  local file = io.open(full_path, "w")
  if file then
    file:write(content_string)
    file:close()
    return full_path
  else
    vim.notify("Failed to write content", vim.log.levels.ERROR)
    return nil
  end
end

local typst_template = [[
#import "@preview/physica:0.9.5": *
#let image_viewer(path: "", desc: "", dark-adapt: false, adapt-mode: "darken", width-ratio: 0.6) = {
  figure(image(path, width: width-ratio * 100%), caption: if desc != "" { desc } else { none })
}
#let theorem-block(content, title: "Theorem", icon: "📐", number: none, border-color: rgb("#3498db"), bg-color: rgb("#e8f4f8"), text-color: rgb("#2c3e50")) = {
  quote(block: true, [ #title #icon #content ])
}
#let theorem(content, title: "", number: none) = theorem-block(content, title: "Theorem " + title)
#let claim(content, number: none) = theorem-block(content, title: "Claim", icon: "💡", border-color: rgb("#f39c12"), bg-color: rgb("#fef5e7"), text-color: rgb("#7d6608"))
#let remark(content, number: none) = theorem-block(content, title: "Remark", icon: "💭", border-color: rgb("#9b59b6"), bg-color: rgb("#f4ecf7"), text-color: rgb("#5b2c5f"))
#let proof(content, title: "Proof") = { block(fill: rgb("#f9f9f9"), inset: 6pt, radius: 4pt, stroke: (left: 2pt + rgb("#95a5a6")), [ #text(weight: "bold")[📓 #title.] #content #text(weight: "bold")[END of Proof] ]) }
#let question(content, number: none) = theorem-block(content, title: "Question", icon: "❓", border-color: rgb("#e74c3c"), bg-color: rgb("#fadbd8"), text-color: rgb("#922b21"))
#let custom-block(content, title: "Note", icon: "📌", number: none, border-color: rgb("#16a085"), bg-color: rgb("#e8f8f5"), text-color: rgb("#0d3d35")) = theorem-block(content, title: title, icon: icon, border-color: border-color, bg-color: bg-color, text-color: text-color)
]]

local function typst_script(content)
  local content_string = replace_commutative_diagrams_with_images(0) or content.content
  local start_marker = "// {content: start}"
  local marker_pos = content_string:find(start_marker, 1, true)
  if marker_pos then
    local line_end = content_string:find("\n", marker_pos)
    if line_end then
      content_string = content_string:sub(line_end + 1)
    end
  end
  content_string = typst_template .. "\n" .. content_string

  -- 移除 blog-preview 相关的替换，因为它可能破坏路径
  local lines = vim.split(content_string, "\n")
  -- lines[1] = lines[1]:gsub("blog%.typ", "blog-preview.typ")
  content_string = table.concat(lines, "\n")

  local title = get_typst_title(0) or content.title
  local path = write_content_to_tempfile_and_return_path(content_string, content.path) or content.path
  local dir_path = vim.fn.getcwd()
  local output = { title = title, content = "" }
  local cmd = {
    "pandoc",
    path,
    "-t",
    "markdown",
    "--lua-filter=" .. vim.fn.stdpath("config") .. "/typ_md.lua",
  }
  local ok, result = pcall(function()
    local job = vim.system(cmd, { cwd = dir_path, text = true }):wait()
    if job.code ~= 0 then
      error("Pandoc failed: " .. (job.stderr or ""))
    end
    return job.stdout
  end)

  -- 清理临时文件
  if path:match("converted_content_") then
    os.remove(path)
  end

  if ok then
    output.content = result
  else
    output.content = "Error: " .. result
  end
  return output
end

local function get_tex_title(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "latex")
  if not ok or not parser then
    return nil
  end
  local tree = parser:parse()[1]
  if not tree then
    return nil
  end
  local root = tree:root()
  local query_str = [[
    (title_declaration
      text: (curly_group
        (generic_command
          arg: (curly_group
            (_) @word))))
  ]]
  local query = vim.treesitter.query.parse("latex", query_str)
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local capture_name = query.captures[id]
    if capture_name == "word" then
      local text = vim.treesitter.get_node_text(node, bufnr)
      return text
    end
  end
  return nil
end

local function tex_script(content)
  local content_string = content.content or ""
  local title = get_tex_title(0) or content.title
  local path = write_content_to_tempfile_and_return_path(content_string, content.path, ".tex") or content.path
  local output = { title = title, content = "" }
  local file_dir = vim.fn.fnamemodify(path, ":h")
  local cmd = {
    "pandoc",
    path,
    "-t",
    "markdown",
    "--lua-filter=" .. vim.fn.stdpath("config") .. "/tex_md.lua",
  }
  local ok, result = pcall(function()
    local job = vim.system(cmd, { cwd = file_dir }):wait()
    if job.code ~= 0 then
      error("Pandoc failed: " .. (job.stderr or ""))
    end
    return job.stdout
  end)
  os.remove(path)
  if ok then
    output.content = result
  else
    output.content = "Error: " .. result
  end
  print(output.content)
  return output
end

-- =============================================================================
-- Plugin Config
-- =============================================================================

return {
  "pxwg/zhihu.nvim",
  main = "zhihu",
  dev = true,

  -- 配置你的自定义脚本
  opts = {
    script = {
      typst = { pattern = "*.typ", extension = { typ = "typst" }, script = typst_script },
      tex = { pattern = "*.tex", extension = { tex = "tex" }, script = tex_script },
    },
  },

  -- 在 config 中注册自定义命令
  config = function(_, opts)
    require("zhihu").setup(opts)

    vim.api.nvim_create_user_command("ZhihuUploadArticle", function()
      local ft = vim.bo.filetype
      if ft ~= "typst" then
        vim.notify("ZhihuUploadArticle only works on typst files", vim.log.levels.WARN)
        return
      end

      vim.notify("Converting Typst to Markdown...", vim.log.levels.INFO)
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local content_input = {
        content = table.concat(lines, "\n"),
        path = vim.api.nvim_buf_get_name(0),
        title = get_typst_title(0) or "Untitled",
      }

      local result = typst_script(content_input)
      if result.content:match("^Error:") then
        vim.notify(result.content, vim.log.levels.ERROR)
        return
      end

      local markdown = result.content
      local title = result.title

      vim.notify("Uploading images to Zhihu...", vim.log.levels.INFO)
      local Image = require("zhihu.image").Image

      -- 匹配 ![](path) 格式的图片
      markdown = markdown:gsub("!%[(.-)%]%((.-)%)", function(alt, path)
        local expanded_path = vim.fn.expand(path)
        -- 只有文件存在且是本地路径时才上传
        if vim.fn.filereadable(expanded_path) == 1 then
          local img_obj = Image.from_file(expanded_path)
          -- state=1 表示上传成功
          if img_obj and img_obj.upload_file and img_obj.upload_file.state == 1 then
            local remote_url = tostring(img_obj)
            print("Uploaded: " .. path .. " -> " .. remote_url)
            return string.format("![%s](%s)", alt, remote_url)
          else
            vim.notify("Failed to upload image: " .. path, vim.log.levels.WARN)
          end
        end
        return nil -- 保持原样
      end)

      -- D. 上传文章草稿
      vim.notify("Uploading draft...", vim.log.levels.INFO)
      local Article = require("zhihu.article.markdown").Article
      local article = Article({ title = title })
      article:set_content(markdown)

      -- 调用 update (新建或更新)
      local err = article:update()

      if err then
        vim.notify("Upload failed: " .. tostring(err), vim.log.levels.ERROR)
      else
        vim.notify(string.format("Success! Uploaded '%s' (ID: %s)", title, article.itemId), vim.log.levels.INFO)
      end
    end, {})
  end,
}
