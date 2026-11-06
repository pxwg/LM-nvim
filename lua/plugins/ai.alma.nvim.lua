local function alma_keymap(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
end

local function submit_alma_chat()
  require("alma").submit()
end

local function close_alma_chat()
  require("alma.ui.window").close({})
end

return {
  "pxwg/alma.nvim",
  dev = true,
  enabled = vim.g.alma_enabled or false,
  cmd = {
    "Alma",
    "AlmaHealth",
    "AlmaThreadOpen",
    "AlmaThreadRefresh",
    "AlmaSubmit",
    "AlmaStop",
    "AlmaThreads",
    "AlmaThreadsGlobal",
    "AlmaProjects",
    "AlmaModels",
    "AlmaTools",
    "AlmaSkills",
    "AlmaMCPServers",
    "AlmaBuffers",
    "AlmaEvents",
    "AlmaToolDetails",
    "AlmaAgentCrew",
    "AlmaToggleBlock",
    "AlmaQuickfix",
    "AlmaBlockQuickfix",
    "AlmaDiff",
  },
  keys = {
    {
      "<leader>am",
      function()
        vim.cmd("AlmaThreads")
      end,
      desc = "Alma Thread",
    },
    {
      "<leader>aM",
      function()
        vim.cmd("AlmaThreadsGlobal")
      end,
      desc = "Alma Thread Global",
    },
    -- {
    --   "<C-c>",
    --   function()
    --     vim.cmd("Alma")
    --   end,
    --   desc = "Alma",
    -- },
  },
  config = function()
    require("alma").setup({
      model = "plugin:openai-codex-auth:openai-codex:gpt-5.5",
      reasoning_effort = "xhigh",
      window_layout = "sidebar",
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "alma",
      group = vim.api.nvim_create_augroup("AlmaBuffer", { clear = true }),
      callback = function(event)
        alma_keymap(event.buf, { "n", "i" }, "<C-S>", submit_alma_chat, "Alma Submit")
        alma_keymap(event.buf, { "n", "i" }, "<C-s>", submit_alma_chat, "Alma Submit")
        alma_keymap(event.buf, "n", "<CR>", submit_alma_chat, "Alma Submit")
        alma_keymap(event.buf, "n", "q", close_alma_chat, "Alma Close Chat")
        require("util.rime_ls").attach_rime_to_buffer(event.buf)
      end,
    })
  end,
}
