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
      table.insert(ranges, {
        start_line = start_row + 1,
        end_line = end_row + 1,
      })
    end
  end

  return ranges
end

local function replace_commutative_diagrams_with_images(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Get all text lines
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local full_text = table.concat(lines, "\n")

  -- Get commutative diagram ranges
  local ranges = get_commutative_diagram_ranges(bufnr)
  if #ranges == 0 then
    return full_text
  end

  -- Create figs directory
  local figs_dir = vim.fn.expand("~/figs")
  vim.fn.mkdir(figs_dir, "p")

  -- Template for Typst compilation
  local template = [[
#import "@preview/physica:0.9.5": *
#import "@preview/commute:0.3.0": arr, commutative-diagram, node
#import "@preview/cetz:0.4.2": canvas, draw

#set page(
  width: auto,
  height: auto,
  margin: 0cm
)
#let CS = math.upright("CS")
#let wedge = math.and
#let GL = math.upright("GL")
#let Conf = math.upright("Conf")
#let Hol = math.upright("Hol")

#let string-diagram(top-conn, bottom-conn, color: color) = {
  let x = (0, 4, 8)
  let y = (3, 9)
  let height = 12

  let hline(conn, y-level) = {
    let (x1, x2) = if conn == "12" {
      (x.at(0), x.at(1))
    } else if conn == "13" {
      (x.at(0), x.at(2))
    } else {
      (x.at(1), x.at(2))
    }

    draw.line((x1, y-level), (x2, y-level), stroke: color)
    draw.circle((x1, y-level), radius: 0.6, stroke: color)
    draw.circle((x2, y-level), radius: 0.6, stroke: color)
  }

  canvas(length: 2pt, {
    for i in (0, 1, 2) {
      draw.line((x.at(i), 0), (x.at(i), height), stroke: color)
    }
    hline(top-conn, y.at(1))
    hline(bottom-conn, y.at(0))
  })
}

#let equation-frame(content) = {
  if type(content) == function {
    content(string-diagram.with(color: black))
  } else {
    content
  }
}

%s
]]

  -- Process ranges in reverse order to maintain line numbers
  table.sort(ranges, function(a, b)
    return a.start_line > b.start_line
  end)

  local result_lines = vim.list_extend({}, lines)

  for i, range in ipairs(ranges) do
    -- Extract diagram content
    local diagram_lines = {}
    for line_num = range.start_line, range.end_line do
      table.insert(diagram_lines, lines[line_num])
    end
    local diagram_content = table.concat(diagram_lines, "\n")

    -- Create temporary Typst file
    local temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
    local typst_file = temp_dir .. "/diagram.typ"
    local pdf_file = temp_dir .. "/diagram.pdf"
    local png_file = figs_dir .. "/diagram_" .. i .. ".png"

    -- Write Typst content
    local typst_content = string.format(template, diagram_content)
    local file = io.open(typst_file, "w")
    if file then
      file:write(typst_content)
      file:close()
    else
      vim.notify("Failed to create Typst file: " .. typst_file, vim.log.levels.ERROR)
      goto continue
    end

    -- Compile Typst to PDF
    local compile_cmd = string.format("typst compile '%s' '%s'", typst_file, pdf_file)
    local compile_result = vim.fn.system(compile_cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("Typst compilation failed: " .. compile_result, vim.log.levels.ERROR)
      goto continue
    end

    -- Convert PDF to PNG using ImageMagick
    local convert_cmd = string.format(
      "convert -density 300 '%s' -background white -alpha remove -alpha off -quality 90 '%s'",
      pdf_file,
      png_file
    )
    local convert_result = vim.fn.system(convert_cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("PDF to PNG conversion failed: " .. convert_result, vim.log.levels.ERROR)
      goto continue
    end

    -- Replace diagram with image reference
    local image_ref = string.format('#image("%s")', png_file)

    -- Replace lines in result from bottom to top
    for line_idx = range.end_line, range.start_line, -1 do
      table.remove(result_lines, line_idx)
    end
    table.insert(result_lines, range.start_line, image_ref)

    -- Cleanup temporary files
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
  local root = tree:root()
  local query_str = [[
    (let
      pattern: (ident) @cmd
      (#eq? @cmd "title")
      value: (string) @title)
  ]]
  local query = vim.treesitter.query.parse("typst", query_str)
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local capture_name = query.captures[id]
    if capture_name == "title" then
      local text = vim.treesitter.get_node_text(node, bufnr)
      return text:match('^"(.*)"$') or text
    end
  end

  return nil
end

local function write_content_to_tempfile_and_return_path(content_string, orig_path, ft)
  ft = ft or ".typ"
  -- Get directory of the original file
  local dir = vim.fn.fnamemodify(orig_path, ":h")
  -- Generate a unique filename in the same directory
  local filename = "converted_content_" .. tostring(os.time()) .. ft
  print(filename)
  local full_path = dir .. "/" .. filename

  -- Write content_string to the file
  local file = io.open(full_path, "w")
  if file then
    file:write(content_string)
    file:close()
    return full_path
  else
    vim.notify("Failed to write content to file: " .. full_path, vim.log.levels.ERROR)
    return nil
  end
end

local typst_template = [[
#import "@preview/physica:0.9.5": *

#let image_viewer(
  path: "",
  desc: "",
  dark-adapt: false,
  adapt-mode: "darken",
  width-ratio: 0.6,
) = {
  let img-width = width-ratio * 100%
  figure(
    image(path, width: img-width),
    caption: if desc != "" { desc } else { none },
  )
}

#let theorem-block(
  content,
  title: "Theorem",
  icon: "📐",
  number: none,
  border-color: rgb("#3498db"),
  bg-color: rgb("#e8f4f8"),
  text-color: rgb("#2c3e50"),
) = {
  let full-title = if number != none {
    title + " " + str(number)
  } else {
    title
  }
  quote(block: true, [
    #full-title #icon

    #content
  ])
}

// Theorem
#let theorem(content, title: "", number: none) = theorem-block(
  content,
  title: "Theorem " + title,
  icon: "📐",
  number: number,
  border-color: rgb("#3498db"),
  bg-color: rgb("#e8f4f8"),
  text-color: rgb("#2c3e50"),
)

// Claim
#let claim(content, number: none) = theorem-block(
  content,
  title: "Claim",
  icon: "💡",
  number: number,
  border-color: rgb("#f39c12"),
  bg-color: rgb("#fef5e7"),
  text-color: rgb("#7d6608"),
)

// Remark
#let remark(content, number: none) = theorem-block(
  content,
  title: "Remark",
  icon: "💭",
  number: number,
  border-color: rgb("#9b59b6"),
  bg-color: rgb("#f4ecf7"),
  text-color: rgb("#5b2c5f"),
)

// Proof
#let proof(content, title: "Proof") = {
  block(
    width: 100%,
    inset: 6pt,
    radius: 4pt,
    fill: rgb("#f9f9f9"),
    stroke: (left: 2pt + rgb("#95a5a6")),
    collapse: true,
    [
      #text(fill: rgb("#95a5a6"), weight: "bold", size: 0.95em)[📓 #title.]
      #v(0.1em)
      #text(fill: rgb("#34495e"), size: 0.95em)[#content]
      #v(0.1em)
      #text(weight: "bold")[END of Proof]
    ],
  )
}

// Question
#let question(content, number: none) = theorem-block(
  content,
  title: "Question",
  icon: "❓",
  number: number,
  border-color: rgb("#e74c3c"),
  bg-color: rgb("#fadbd8"),
  text-color: rgb("#922b21"),
)

// Custom block with configurable colors
#let custom-block(
  content,
  title: "Note",
  icon: "📌",
  number: none,
  border-color: rgb("#16a085"),
  bg-color: rgb("#e8f8f5"),
  text-color: rgb("#0d3d35"),
) = theorem-block(
  content,
  title: title,
  icon: icon,
  number: number,
  border-color: border-color,
  bg-color: bg-color,
  text-color: text-color,
)
]]

local function typst_script(content)
  local content_string = replace_commutative_diagrams_with_images(0) or content.content

  local start_marker = "// {content: start}"
  local marker_pos = content_string:find(start_marker, 1, true)
  if marker_pos then
    -- Find the end of the line containing the marker
    local line_end = content_string:find("\n", marker_pos)
    if line_end then
      -- Extract content from after the marker line
      content_string = content_string:sub(line_end + 1)
    end
  end
  content_string = typst_template .. "\n" .. content_string

  local lines = vim.split(content_string, "\n")
  lines[1] = lines[1]:gsub("blog%.typ", "blog-preview.typ")
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
    local job = vim.system(cmd, { cwd = dir_path }):wait()
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
  -- print(output.content)
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

return {
  -- "pxwg/zhihu_neovim",
  "pxwg/zhihu.nvim",
  main = "zhihu",
  -- cmd = { "ZhihuAuth" },
  -- ft = { "typst", "markdown", "tex" },
  enabled = false,
  dev = true,
  ---@type ZhnvimConfigs
  opts = {
    script = {
      typst = { pattern = "*.typ", extension = { typ = "typst" }, script = typst_script },
      tex = { pattern = "*.tex", extension = { tex = "tex" }, script = tex_script },
    },
  },
}
