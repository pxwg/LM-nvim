local opts = {
  executable = "zk-lsp",
  wiki_root = vim.fs.normalize(vim.fn.expand("~/wiki")),
}

local function note_id_under_cursor()
  local id = vim.fn.expand("<cword>")
  return id:match("^%d%d%d%d%d%d%d%d%d%d$") and id or nil
end

local function current_note_id()
  return vim.api.nvim_buf_get_name(0):match("/note/(%d%d%d%d%d%d%d%d%d%d)%.typ$")
end

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "zk-lsp.nvim" })
end

local function confirm_remove(id)
  if not id then
    notify("No valid note id.", vim.log.levels.WARN)
    return
  end

  vim.ui.select({ "Yes", "No" }, { prompt = "Remove note " .. id .. "?" }, function(choice)
    if choice == "Yes" then
      vim.cmd("Zk remove " .. id)
    else
      notify("Aborted removing note " .. id .. ".")
    end
  end)
end

local function local_zk_scripts()
  local ok, scripts = pcall(require, "zk_scripts")
  if ok then
    return scripts
  end
  notify("zk_scripts is not available", vim.log.levels.WARN)
  return nil
end

return {
  dir = vim.fn.expand("~/zk-lsp.nvim"),
  name = "zk-lsp.nvim",
  event = "VeryLazy",
  dependencies = {
    "folke/snacks.nvim",
  },
  build = function()
    require("zk_lsp").build(opts)
  end,
  config = function()
    require("zk_lsp").setup(opts)
  end,
  keys = {
    { "zn", "<cmd>Zk new<cr>", desc = "[Z]ettel [N]ew" },
    { "zs", "<cmd>Zk search<cr>", desc = "[Z]ettel [S]earch" },
    { "<leader>fz", "<cmd>Zk search<cr>", desc = "[F]ind [Z]ettel" },
    { "zt", "<cmd>Zk search todo<cr>", desc = "[Z]ettel [T]ODO Search" },
    { "<leader>fo", "<cmd>Zk search orphans<cr>", desc = "[F]ind [O]rphan Zettels" },
    {
      "ze",
      function()
        local id = current_note_id() or note_id_under_cursor()
        if not id then
          notify("No note id for export.", vim.log.levels.WARN)
          return
        end
        vim.cmd("Zk export " .. id .. " --depth 5 --inverse")
      end,
      desc = "[Z]ettel [E]xport",
    },
    {
      "zr",
      function()
        confirm_remove(note_id_under_cursor())
      end,
      desc = "[Z]ettel [R]emove",
    },
    {
      "zR",
      function()
        confirm_remove(current_note_id())
      end,
      desc = "[Z]ettel [R]emove (Buffer)",
    },
    {
      "zS",
      function()
        local scripts = local_zk_scripts()
        if scripts and scripts.show_startup_summary then
          scripts.show_startup_summary()
        end
      end,
      desc = "[Z]ettel [S]tartup Summary",
    },
    {
      "<leader>zo",
      function()
        local scripts = local_zk_scripts()
        if scripts and scripts.open_pdf_at_cursor then
          scripts.open_pdf_at_cursor()
        end
      end,
      desc = "[Z]ettel [O]pen PDF at page",
    },
    {
      "<C-t>",
      function()
        local scripts = local_zk_scripts()
        if scripts and scripts.toggle_todo then
          scripts.toggle_todo()
        end
      end,
      desc = "[Z]ettel Toggle TODO",
    },
  },
}
