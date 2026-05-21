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

local function is_copilot_chat_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  return vim.bo[bufnr].filetype == "copilot-chat" or name:match("copilot%-chat") ~= nil
end

local attach_copilot_chat_formula_images

local function set_conceal_for_buffer_windows(bufnr)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_option_value("conceallevel", 2, { win = winid })
      vim.api.nvim_set_option_value("concealcursor", "nci", { win = winid })
    end
  end
end

local function schedule_copilot_chat_formula_attach(bufnr, delay_ms)
  if not is_copilot_chat_buffer(bufnr) or vim.b[bufnr].copilot_chat_formula_attach_pending then
    return
  end

  vim.b[bufnr].copilot_chat_formula_attach_pending = true
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].copilot_chat_formula_attach_pending = false
      attach_copilot_chat_formula_images(bufnr)
    end
  end, delay_ms or 120)
end

attach_copilot_chat_formula_images = function(bufnr, attempt)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  attempt = attempt or 1
  if not is_copilot_chat_buffer(bufnr) then
    return
  end

  if vim.bo[bufnr].filetype == "" then
    vim.bo[bufnr].filetype = "copilot-chat"
  end
  set_conceal_for_buffer_windows(bufnr)

  local ok_main, image_concealer = pcall(require, "math-conceal.image")
  local ok_runtime, runtime = pcall(require, "math-conceal.image.machine.runtime")
  if not ok_main or not ok_runtime then
    if attempt < 5 then
      vim.defer_fn(function()
        attach_copilot_chat_formula_images(bufnr, attempt + 1)
      end, 500)
    else
      vim.notify("math-conceal.image is not loaded for CopilotChat buffer", vim.log.levels.WARN)
    end
    return
  end

  image_concealer._enabled_buffers[bufnr] = true
  if not vim.b[bufnr].copilot_chat_formula_tracker_attached then
    vim.api.nvim_buf_attach(bufnr, false, {
      on_lines = function(_, changed_buf)
        schedule_copilot_chat_formula_attach(changed_buf, 120)
      end,
      on_detach = function(_, detached_buf)
        if vim.api.nvim_buf_is_valid(detached_buf) then
          vim.b[detached_buf].copilot_chat_formula_tracker_attached = false
        end
      end,
    })
    vim.b[bufnr].copilot_chat_formula_tracker_attached = true
  end

  local ok_render, err = pcall(runtime.render_buf, bufnr)
  if not ok_render then
    vim.notify("CopilotChat formula render failed: " .. tostring(err), vim.log.levels.WARN)
    return
  end

  for _, delay_ms in ipairs({ 800, 1800, 3200 }) do
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) and image_concealer._enabled_buffers[bufnr] == true then
        pcall(runtime.refresh_visible_overlays, bufnr, { force_reupload_blocks = true, margin = 8 })
      end
    end, delay_ms)
  end
end

return {
  "PartyWumpus/typst-concealer",
  enabled = false,
  dev = true,
  dir = "/Users/pxwg-dogggie/typst-concealer",
  opts = {
    service_binary = "/Users/pxwg-dogggie/typst-concealer/service/target/release/typst-concealer-service",
    use_compiler_service = true,
    use_formula_service = true,
    backends = {
      latex = {
        enabled = true,
        compiler = "pdflatex",
        converter = "pdftocairo",
      },
    },
    markdown_filetypes = { "markdown", "copilot-chat" },
    live_preview_debounce = 0,
    cursor_hover_throttle_ms = 0,
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
    get_preamble_file = function(_bufnr, path, _cwd, _kind)
      if path:match("/wiki/") then
        return vim.fn.expand("~/wiki/concealer-context.typ")
      end
    end,
    get_inputs = function(_bufnr, path, _cwd, _kind)
      local id = vim.fn.fnamemodify(path, ":t:r")
      return {
        "focus=" .. id,
        "preview=true",
        "preview-concealer=true",
      }
    end,
  },
  config = function(_, opts)
    require("math-conceal.image").setup(opts)

    local group = vim.api.nvim_create_augroup("CopilotChatFormulaImages", { clear = true })
    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "BufEnter" }, {
      group = group,
      callback = function(event)
        if is_copilot_chat_buffer(event.buf) then
          schedule_copilot_chat_formula_attach(event.buf, 120)
        end
      end,
    })
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = group,
      callback = function(event)
        if is_copilot_chat_buffer(event.buf) then
          schedule_copilot_chat_formula_attach(event.buf, 120)
        end
      end,
    })

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if is_copilot_chat_buffer(bufnr) then
        schedule_copilot_chat_formula_attach(bufnr, 120)
      end
    end
  end,
  ft = { "markdown", "typst", "copilot-chat", "tex" },
}
