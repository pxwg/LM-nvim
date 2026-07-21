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

local math_conceal_service_binary =
  "/Users/pxwg-dogggie/math-conceal.nvim/service/target/release/typst-concealer-service"

local typst_math_header = [[
      // #show math.equation: set text(font: "Fira Math")
      #show math.equation.where(block: false): it => {
        set text(size: 0.85em)
        it
      }
    ]]

local typst_code_render_allowlist = {
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
}

local function math_renderer_root(ctx)
  if is_wiki_path(ctx.path) then
    return wiki_root
  end
  return find_git_root(ctx.path) or ctx.cwd
end

local function math_renderer_inputs(ctx)
  local id = vim.fn.fnamemodify(ctx.path, ":t:r")
  return {
    "focus=" .. id,
    "concealed=true",
    "preview=true",
    "preview-concealer=true",
  }
end

local function math_renderer_preamble_file(ctx)
  if is_wiki_path(ctx.path) then
    return wiki_concealer_context
  end
end

local function math_renderer_path_excluded(ctx)
  return excluded_render_paths[vim.fs.normalize(ctx.path)] == true
end

local function is_copilot_chat_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  return vim.bo[bufnr].filetype == "copilot-chat" or name:match("copilot%-chat") ~= nil
end

local function coact_buffer_role(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local filetype = vim.bo[bufnr].filetype
  if filetype == "coact-input" or vim.b[bufnr].coact_role == "composer" or vim.b[bufnr].coact_composer == true then
    return "input"
  end
  if filetype == "coact-history" or vim.b[bufnr].coact_role == "history" then
    return "history"
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if filetype == "coact" or name:match("^coact://") ~= nil then
    return "history"
  end

  return nil
end

local function is_coact_buffer(bufnr)
  return coact_buffer_role(bufnr) ~= nil
end

local function coact_math_conceal_mode(bufnr)
  return coact_buffer_role(bufnr) == "input" and "edit" or "presentation"
end

local function is_ai_chat_buffer(bufnr)
  return is_copilot_chat_buffer(bufnr) or is_coact_buffer(bufnr)
end

local math_conceal_filetypes = {
  plaintex = true,
  tex = true,
  context = true,
  bibtex = true,
  typst = true,
  markdown = true,
  coact = true,
  ["coact-history"] = true,
  ["coact-input"] = true,
}

local function is_math_conceal_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  return is_ai_chat_buffer(bufnr) or math_conceal_filetypes[vim.bo[bufnr].filetype] == true
end

local function apply_math_conceal_buffer_mode(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if not is_math_conceal_buffer(bufnr) then
    return
  end

  local ok, math_conceal = pcall(require, "math-conceal")
  if not ok or math_conceal.setup_buffer == nil then
    return
  end

  local desired_mode = "edit"
  -- if is_copilot_chat_buffer(bufnr) then
  --   desired_mode = "presentation"
  -- elseif is_coact_buffer(bufnr) then
  --   desired_mode = coact_math_conceal_mode(bufnr)
  -- end
  if
    vim.b[bufnr].math_conceal_applied_buffer_mode == desired_mode
    and type(math_conceal.get_buffer_config) == "function"
  then
    local ok_config, config = pcall(math_conceal.get_buffer_config, bufnr)
    if ok_config and config and config.mode == desired_mode then
      return
    end
  end

  math_conceal.setup_buffer(bufnr, {
    mode = desired_mode,
  })
  vim.b[bufnr].math_conceal_applied_buffer_mode = desired_mode
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
      buffer = {
        mode = "edit",
      },
      opt = { concealcursor = "nci" },
      image = {
        enabled = true,
        -- enabled = false,
        tracker = {
          debug = false,
        },
        renderers = {
          typst = {
            filetypes = { "typst" },
            service_binary = math_conceal_service_binary,
            live_debounce = 0,
            header = typst_math_header,
            code_render = {
              allow = typst_code_render_allowlist,
            },
            root = math_renderer_root,
            inputs = math_renderer_inputs,
            preamble_file = math_renderer_preamble_file,
            render_paths = {
              exclude = {
                math_renderer_path_excluded,
              },
            },
          },
          markdown = {
            filetypes = { "markdown", "copilot-chat", "coact", "coact-history" },
            service_binary = math_conceal_service_binary,
            live_debounce = 0,
            header = typst_math_header,
            root = math_renderer_root,
            inputs = math_renderer_inputs,
            preamble_file = math_renderer_preamble_file,
            mitex_package = "@preview/mitex:0.2.7",
            render_paths = {
              exclude = {
                math_renderer_path_excluded,
              },
            },
          },
        },
        ppi = 300,
        math_baseline_pt = 11,
        styling_type = "colorscheme",
        color = nil,
        cursor_hover_throttle_ms = 0,
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
    config = function(_, opts)
      require("math-conceal").setup(opts)

      local group = vim.api.nvim_create_augroup("MathConcealBufferMode", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = {
          "plaintex",
          "tex",
          "context",
          "bibtex",
          "typst",
          "markdown",
          "coact",
          "coact-history",
          "coact-input",
          "copilot-chat",
        },
        callback = function(event)
          apply_math_conceal_buffer_mode(event.buf)
        end,
      })

      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        apply_math_conceal_buffer_mode(bufnr)
      end
    end,
  },
}
