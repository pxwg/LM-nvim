return {
  {
    "prochri/telescope-all-recent.nvim",
    enabled = function()
      return vim.g.picker == "telescope"
    end,
    event = "VeryLazy",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "kkharji/sqlite.lua",
      "stevearc/dressing.nvim",
    },
    opts = {},
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    enabled = function()
      return vim.g.picker == "telescope"
    end,
    version = false,
    keys = {
      {
        "<leader>,",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
        desc = "Switch Buffer",
      },
      {
        "<leader>/",
        function()
          require("telescope.builtin").live_grep({
            cwd = require("util.cwd_attach").cwd(),
            layout_strategy = "horizontal",
            layout_config = { width = 0.8, height = 0.8 },
          })
        end,
        desc = "[G]rep (Root Dir)",
      },
      {
        "<leader>:",
        "<cmd>Telescope command_history<cr>",
        desc = "Command History",
      },
      {
        "<leader><space>",
        function()
          require("telescope.builtin").find_files({
            cwd = require("util.cwd_attach").cwd(),
            layout_strategy = "horizontal",
            layout_config = { width = 0.5 },
            theme = "cursor",
          })
        end,
        desc = "Find Files (cwd)",
      },
      {
        "<leader>fb",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true ignore_current_buffer=true<cr>",
        desc = "[B]uffers",
      },
      {
        "<leader>fc",
        "<cmd>Telescope find_files cwd=~/.config/nvim<cr>",
        desc = "Find [C]onfig File",
      },
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files({
            cwd = require("util.cwd_attach").cwd(),
          })
        end,
        desc = "Find [F]iles (cwd)",
      },
      {
        "<leader>fF",
        "<cmd>Telescope find_files<cr>",
        desc = "Find [F]iles (Root Dir)",
      },
      {
        "<leader>fg",
        "<cmd>Telescope git_files<cr>",
        desc = "Find [G]it",
      },
      {
        "<leader>fr",
        "<cmd>Telescope oldfiles<cr>",
        desc = "[R]ecent",
      },
      {
        "<leader>fR",
        "<cmd>Telescope oldfiles cwd=%:p:h<cr>",
        desc = "[R]ecent (cwd)",
      },
      {
        "<leader>gc",
        "<cmd>Telescope git_commits<CR>",
        desc = "[C]ommits",
      },
      {
        "<leader>gs",
        "<cmd>Telescope git_status<CR>",
        desc = "[S]tatus",
      },
      {
        "<leader>sf",
        "<cmd>Telescope current_buffer_fuzzy_find<cr>",
        desc = "[F]uzzy Find",
      },
      {
        "<leader>sd",
        "<cmd>Telescope diagnostics bufnr=0<cr>",
        desc = "[D]iagnostics",
      },
      {
        "<leader>sD",
        "<cmd>Telescope diagnostics<cr>",
        desc = "Workspace [D]iagnostics",
      },
      {
        "<leader>sg",
        "<cmd>Telescope live_grep cwd=%:p:h<cr>",
        desc = "[G]rep (cwd)",
      },
      {
        "<leader>sG",
        "<cmd>Telescope live_grep<cr>",
        desc = "[G]rep (Root Dir)",
      },
      {
        "<leader>sH",
        "<cmd>Telescope highlights<cr>",
        desc = "Search [H]ighlight Groups",
      },
      {
        "<leader>sj",
        "<cmd>Telescope jumplist<cr>",
        desc = "[J]umplist",
      },
      {
        "<leader>so",
        "<cmd>Telescope vim_options<cr>",
        desc = "[O]ptions",
      },
      {
        "<leader>ss",
        "<cmd>Telescope grep_string word_match=-w<cr>",
        desc = "[S]tring (Root Dir)",
      },
      {
        "<leader>sS",
        "<cmd>Telescope grep_string cwd=%:p:h word_match=-w<cr>",
        desc = "[S]tring (cwd)",
      },
      {
        "<leader>ss",
        "<cmd>Telescope grep_string<cr>",
        mode = "v",
        desc = "[S]election (Root Dir)",
      },
      {
        "<leader>sS",
        "<cmd>Telescope grep_string cwd=%:p:h<cr>",
        mode = "v",
        desc = "[S]election (cwd)",
      },
      {
        "<leader>uC",
        "<cmd>Telescope colorscheme enable_preview=true<cr>",
        desc = "[C]olorscheme with Preview",
      },
    },
    configs = function()
      -- require("telescope").setup(require("plugins.fuzzy.telescope").opts())
      require("telescope").load_extension("fzf")
      -- require("telescope").load_extension("file_browser")
      -- require("telescope").load_extension("all_recent")
    end,
    opts = function()
      if vim.g.started_by_firenvim or vim.g.neovide or vim.fn.has("gui") ~= 0 then
        return
      end
      local actions = require("telescope.actions")
      -- local image_preview = require("util.telescope-figure").telescope_image_preview()

      local function find_command()
        if 1 == vim.fn.executable("rg") then
          return { "rg", "--files", "--color", "never", "-g", "!.git" }
        elseif 1 == vim.fn.executable("fd") then
          return { "fd", "--type", "f", "--color", "never", "-E", ".git" }
        elseif 1 == vim.fn.executable("fdfind") then
          return { "fdfind", "--type", "f", "--color", "never", "-E", ".git" }
        elseif 1 == vim.fn.executable("find") and vim.fn.has("win32") == 0 then
          return { "find", ".", "-type", "f" }
        elseif 1 == vim.fn.executable("where") then
          return { "where", "/r", ".", "*" }
        end
      end

      return {
        extensions = {
          file_browser = { hijack_netrw = true },
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          },
        },
        defaults = {
          preview = {
            hide_on_startup = false,
            treesitter = true,
            hilight_limit = false,
          },
          sorting_strategy = "ascending",
          -- file_previewer = image_preview.file_previewer,
          -- buffer_previewer_maker = image_preview.buffer_previewer_maker,
          layout_strategy = "flex",
          layout_config = { height = 0.3, width = 0.7 },
          borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },

          -- prompt_prefix = " ",
          prompt_prefix = "  ",
          selection_caret = " ",
          -- selection_caret = " ",
          get_selection_window = function()
            local wins = vim.api.nvim_list_wins()
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == "" then
                return win
              end
            end
            return 0
          end,
          mappings = {
            i = {
              ["<C-n>"] = actions.move_selection_next,
              ["<C-p>"] = actions.move_selection_previous,
              ["<C-k>"] = actions.preview_scrolling_up,
              ["<C-j>"] = actions.preview_scrolling_down,
              ["<C-Down>"] = actions.cycle_history_next,
              ["<C-Up>"] = actions.cycle_history_prev,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-b>"] = actions.preview_scrolling_up,
              ["<C-x>"] = actions.delete_buffer + actions.move_to_top,
            },
            n = {
              ["q"] = actions.close,
            },
          },
        },
        pickers = {
          find_files = {
            find_command = find_command,
            hidden = true,
            -- theme = "ivy",
          },
        },
      }
    end,
  },
}
