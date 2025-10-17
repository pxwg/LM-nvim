-- Advanced LaTeX filetype plugin for Neovim

local function find_main_tex_file()
  -- Try to find main .tex file by looking for \documentclass
  local files = vim.fn.glob("*.tex", false, true)

  for _, file in ipairs(files) do
    local content = vim.fn.readfile(file, "", 50) -- Read first 50 lines
    for _, line in ipairs(content) do
      if line:match("\\documentclass") then
        return file
      end
    end
  end

  -- Fallback to current file
  return vim.fn.expand("%:t")
end

local function setup_latex_make()
  local cwd = vim.fn.getcwd()
  local main_file = find_main_tex_file()

  -- Configure compiler (can be pdflatex, xelatex, lualatex)
  local compiler = "pdflatex"

  -- Check if there's a specific compiler specified in project
  if vim.fn.filereadable(".latexmkrc") == 1 then
    -- Use latexmk if config exists
    vim.bo.makeprg = string.format("cd %s && latexmk -pdf %s", vim.fn.shellescape(cwd), vim.fn.shellescape(main_file))
  else
    -- Use direct compiler
    vim.bo.makeprg = string.format(
      "cd %s && %s -interaction=nonstopmode -file-line-error -synctex=1 %s",
      vim.fn.shellescape(cwd),
      compiler,
      vim.fn.shellescape(main_file)
    )
  end

  -- Enhanced error format for LaTeX
  vim.bo.errorformat = table.concat({
    "%E!%m",
    "%E%f:%l:%m",
    "%E!%m",
    "%+WLaTeX%.%.%.: %m",
    "%+C%[%^!]%m",
    "%-GSee the LaTeX%m",
    "%-GType %m",
    "%-G %m",
    "%-G%\\s%#%m",
    "%+O(%f)%r",
    "%+P%f%r",
    "%+P**%f%r",
    "%+Q)%r",
    "%-G%.%#",
  }, ",")
end

-- !open %:gusb(".tex", ".pdf")
vim.api.nvim_buf_create_user_command(0, "Open", function()
  local pdf_file = vim.api.nvim_buf_get_name(0):gsub(".tex$", ".pdf")
  if vim.fn.filereadable(pdf_file) == 1 then
    -- Adjust the command based on your OS
    local open_cmd = ""
    if vim.fn.has("mac") == 1 then
      open_cmd = "open"
    elseif vim.fn.has("unix") == 1 then
      open_cmd = "xdg-open"
    elseif vim.fn.has("win32") == 1 then
      open_cmd = "start"
    else
      print("Unsupported OS for opening PDF")
      return
    end
    vim.fn.jobstart({ open_cmd, pdf_file }, { detach = true })
  else
    print("PDF file not found: " .. pdf_file)
  end
end, { desc = "Read pdf" })

-- Setup make command
setup_latex_make()

-- Optional: Auto-compile on save
-- vim.api.nvim_create_autocmd('BufWritePost', {
--   buffer = 0,
--   command = 'make'
-- })
