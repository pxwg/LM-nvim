require("util.rime_blinks")
local rime_ls = require("util.rime_ls")
vim.g.rime_enabled = true

function _G.rime_ls_disabled(context)
  if not vim.g.rime_enabled then
    return true
  end
  local line = context.line
  local cursor_column = context.cursor[2]
  for _, pattern in ipairs(vim.g.disable_rime_ls_pattern or {}) do
    local start_pos = 1
    while true do
      local match_start, match_end = string.find(line, pattern, start_pos)
      if not match_start then
        break
      end
      if cursor_column >= match_start and cursor_column < match_end then
        return true
      end
      start_pos = match_end + 1
    end
  end
  return false
end

local function mention_get_items()
  vim.notify("hello from mention_get_items", vim.log.levels.INFO)
  local items = require("avante.utils").get_mentions()
  local side_bar, _, _ = require("avante").get()

  local timeout_ms = 5000

  local function with_timeout(callback, name)
    return function()
      local completed = false

      vim.schedule(function()
        local success, err = pcall(callback)
        completed = true
        if not success then
          vim.notify(string.format("%s failed: %s", name, err), vim.log.levels.ERROR)
        end
      end)

      vim.defer_fn(function()
        if not completed then
          vim.notify(string.format("%s timed out after %dms", name, timeout_ms), vim.log.levels.WARN)
        end
      end, timeout_ms)
    end
  end

  table.insert(items, {
    description = "file",
    command = "file",
    details = "add files...",
    callback = with_timeout(function()
      vim.notify("Opening file selector...", vim.log.levels.INFO)
      side_bar.file_selector:open()
    end, "File selector"),
  })
  table.insert(items, {
    description = "quickfix",
    command = "quickfix",
    details = "add files in quickfix list to chat context",
    callback = with_timeout(function()
      side_bar.file_selector:add_quickfix_files()
    end, "Quickfix operation"),
  })
  table.insert(items, {
    description = "buffers",
    command = "buffers",
    details = "add open buffers to the chat context",
    callback = with_timeout(function()
      side_bar.file_selector:add_buffer_files()
    end, "Buffer operation"),
  })
  return items
end

return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  -- event = "UIEnter",
  -- enabled = false,
  -- use a release tag to download pre-built binaries
  version = "1.*",
  -- enabled = true,
  -- build = "cargo build --release",
  dependencies = {
    -- add source
    "Kaiser-Yang/blink-cmp-avante",
    "L3MON4D3/LuaSnip",
    "ribru17/blink-cmp-spell",
    "zbirenbaum/copilot-cmp",
    "zbirenbaum/copilot.lua",
    "dmitmel/cmp-digraphs",
    "hrsh7th/cmp-nvim-lsp",
    "giuxtaposition/blink-cmp-copilot",
    { "pxwg/blink-cmp-copilot-chat" },
    -- "jalvesaq/cmp-zotcite",
    {
      "saghen/blink.compat",
      opts = { impersonate_nvim_cmp = true, enable_events = true },
    },
    {
      "Kaiser-Yang/blink-cmp-dictionary",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
  },
  config = function()
    -- if last char is number, and the only completion item is provided by rime-ls, accept it
    local types = require("blink.cmp.types")
    require("blink.cmp.completion.list").show_emitter:on(function(event)
      if #event.items ~= 1 then
        return
      end
      local col = vim.fn.col(".") - 1
      if event.context.line:sub(1, col):match("^.*%a+%d+$") == nil then
        return
      end
      local client = vim.lsp.get_client_by_id(event.items[1].client_id)
      if (not client) or client.name ~= "rime_ls" then
        return
      end
      require("blink.cmp").accept({ index = 1 })
    end)

    -- link BlinkCmpKind to CmpItemKind since nvchad/base46 does not support it
    local set_hl = function(hl_group, opts)
      opts.default = true -- Prevents overriding existing definitions
      vim.api.nvim_set_hl(0, hl_group, opts)
    end
    for _, kind in ipairs(require("blink.cmp.types").CompletionItemKind) do
      set_hl("BlinkCmpKind" .. kind, { link = ("CmpItemKind" .. kind) or "BlinkCmpKind" })
    end

    -- vim.api.nvim_create_autocmd("User", {
    --   pattern = "BlinkCmpMenuOpen",
    --   callback = function()
    --     require("copilot.suggestion").dismiss()
    --     vim.b.copilot_suggestion_hidden = true
    --   end,
    -- })

    -- vim.api.nvim_create_autocmd("User", {
    --   pattern = "BlinkCmpMenuClose",
    --   callback = function()
    --     vim.b.copilot_suggestion_hidden = false
    --   end,
    -- })

    require("copilot_cmp").setup()
    require("blink.cmp").setup({
      keymap = {
        preset = "none",
        ["<cr>"] = { "accept", "fallback" },
        ["<C-y>"] = { "select_and_accept" },
        ["<s-tab>"] = { "snippet_backward", "fallback" },
        ["<c-j>"] = { "scroll_documentation_up", "fallback" },
        ["<c-k>"] = { "scroll_documentation_down", "fallback" },
        ["<c-n>"] = { "select_next", "fallback" },
        ["<down>"] = { "select_next", "fallback" },
        ["<up>"] = { "select_prev", "fallback" },
        ["<c-p>"] = { "select_prev", "fallback" },
        ["<c-x>"] = { "show", "fallback" },
        ["<c-c>"] = { "cancel", "fallback" },
        ["<space>"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(1)
            if #rime_item_index ~= 1 then
              return false
            end
            return cmp.accept({ index = rime_item_index[1] })
          end,
          "fallback",
        },
        ["1"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(1)
            if #rime_item_index ~= 1 then
              return false
            end
            return cmp.accept({ index = rime_item_index[1] })
          end,
          "fallback",
        },
        ["2"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(2)
            if #rime_item_index ~= 2 then
              return false
            end
            return cmp.accept({ index = rime_item_index[2] })
          end,
          "fallback",
        },
        ["3"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(3)
            if #rime_item_index ~= 3 then
              return false
            end
            return cmp.accept({ index = rime_item_index[3] })
          end,
          "fallback",
        },
        ["4"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(4)
            if #rime_item_index ~= 4 then
              return false
            end
            return cmp.accept({ index = rime_item_index[4] })
          end,
          "fallback",
        },
        ["5"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(5)
            if #rime_item_index ~= 5 then
              return false
            end
            return cmp.accept({ index = rime_item_index[5] })
          end,
          "fallback",
        },
        ["6"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(6)
            if #rime_item_index ~= 6 then
              return false
            end
            return cmp.accept({ index = rime_item_index[6] })
          end,
          "fallback",
        },
        ["7"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(7)
            if #rime_item_index ~= 7 then
              return false
            end
            return cmp.accept({ index = rime_item_index[7] })
          end,
          "fallback",
        },
        ["8"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(8)
            if #rime_item_index ~= 8 then
              return false
            end
            return cmp.accept({ index = rime_item_index[8] })
          end,
          "fallback",
        },
        ["9"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(9)
            if #rime_item_index ~= 9 then
              return false
            end
            return cmp.accept({ index = rime_item_index[9] })
          end,
          "fallback",
        },
        [";"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(2)
            if #rime_item_index ~= 2 then
              return false
            end
            return cmp.accept({ index = rime_item_index[2] })
          end,
          "fallback",
        },
        ["'"] = {
          function(cmp)
            if not vim.g.rime_enabled then
              return false
            end
            local rime_item_index = get_n_rime_item_index(3)
            if #rime_item_index ~= 3 then
              return false
            end
            return cmp.accept({ index = rime_item_index[3] })
          end,
          "fallback",
        },
      },
      -- cmdline = { enabled = false },
      completion = {
        ghost_text = { enabled = true },
        documentation = {
          auto_show = true,
          window = {
            min_width = 10,
            max_width = 80,
            max_height = 20,
            -- border = { "󱕦", " ", " ", " ", " ", " ", "󰄛", " " },
            winblend = 0,
            -- winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
            -- Note that the gutter will be disabled when border ~= 'none'
            scrollbar = true,
            -- Which directions to show the documentation window,
            -- for each of the possible menu window directions,
            -- falling back to the next direction when there's not enough space
            direction_priority = {
              menu_north = { "e", "w", "n", "s" },
              menu_south = { "e", "w", "s", "n" },
            },
          },
        },
        menu = {
          auto_show = function(ctx)
            return ctx.mode ~= "cmdline"
          end,
          draw = {
            columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
          },
          -- border = { "󱕦", " ", " ", " ", " ", " ", "󰩃", " " },
          -- winhighlight = "FloatBorder:CmpBorder,Search:BlinkCmpMenuSelection",
          winhighlight = "CursorLine:BlinkCmpMenuSelection",
        },
      },
      signature = {
        enabled = false,
        trigger = {
          enabled = true,
          show_on_trigger_character = false,
          show_on_insert_on_trigger_character = false,
        },
      },
      snippets = { preset = "luasnip" },
      fuzzy = {
        sorts = {
          "score",
          function(a, b)
            local sort = require("blink.cmp.fuzzy.sort")
            if a.source_id == "spell" and b.source_id == "spell" then
              return sort.label(a, b)
            end
          end,
          "kind",
          "label",
        },
      },
      sources = {
        default = { "lsp", "path", "buffer", "copilot", "spell" },
        per_filetype = {
          codecompanion = { "codecompanion", "lsp", "buffer", "path", "copilot" },
          ["copilot-chat"] = { "lsp", "buffer", "path", "copilot", "copilot_c" },
          AvanteInput = {
            "avante",
            "lsp",
            "buffer",
            "path",
            "copilot",
          },
        },
        providers = {
          avante_commands = {
            name = "avante_commands",
            module = "blink.compat.source",
            score_offset = 90, -- show at a higher priority than lsp
            opts = {},
          },
          spell = {
            name = "Spell",
            module = "blink-cmp-spell",
            opts = {
              enable_in_context = function()
                local curpos = vim.api.nvim_win_get_cursor(0)
                local captures = vim.treesitter.get_captures_at_pos(0, curpos[1] - 1, curpos[2] - 1)
                local in_spell_capture = false
                for _, cap in ipairs(captures) do
                  if cap.capture == "spell" and rime_ls.rime_toggle_word() ~= "cn" then
                    in_spell_capture = true
                  elseif cap.capture == "nospell" or rime_ls.rime_toggle_word() == "cn" then
                    return false
                  end
                end
                return in_spell_capture
              end,
            },
          },
          avante_files = {
            name = "avante_files",
            module = "blink.compat.source",
            score_offset = 100, -- show at a higher priority than lsp
            opts = {},
          },
          avante_mentions = {
            name = "avante_mentions",
            module = "blink.compat.source",
            score_offset = 1000, -- show at a higher priority than lsp
            opts = {},
          },
          avante = {
            module = "blink-cmp-avante",
            name = "Avante",
            opts = {
              avante = {
                mention = {
                  triggers = { "@" },
                  get_items = mention_get_items,
                },
              },
            },
          },
          copilot_c = {
            name = "CopilotChat",
            module = "blink-cmp-copilot-chat",
            score_offset = 1000000,
            transform_items = function(_, items)
              -- demote snippets
              for _, item in ipairs(items) do
                -- if item.kind == require("blink.cmp.types").CompletionItemKind.Snippet then
                --   item.score_offset = item.score_offset - 3
                -- end
                if item.kind == require("blink.cmp.types").CompletionItemKind.Avante then
                  item.score_offset = item.score_offset + 10
                end
              end
              return items
            end,
          },
          lsp = {
            min_keyword_length = 0,
            fallbacks = { "ripgrep", "buffer" },
            --- @param ctx blink.cmp.Context
            --- @param items blink.cmp.CompletionItem[]
            transform_items = function(ctx, items)
              local kind = require("blink.cmp.types").CompletionItemKind
              local is_typst = vim.bo.filetype == "typst"

              for _, item in ipairs(items) do
                if is_typst then
                  if item.kind == kind.Field then
                    item.score_offset = (item.score_offset or 0) + 10
                  end

                  if item.kind == kind.Reference then
                    local title = (item.labelDetails and item.labelDetails.description) or item.detail

                    if title and item.label:match("^%d%d%d%d%d%d%d%d%d%d") then
                      local current_filter = item.filterText or item.label
                      item.filterText = title
                    end
                  end
                end
              end
              return items
            end,
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
          dictionary = {
            module = "blink-cmp-dictionary",
            name = "Dict",
            -- Make sure this is at least 2.
            -- 3 is recommended
            min_keyword_length = 3,
            opts = {
              -- options for blink-cmp-dictionary
            },
          },
          buffer = { max_items = 5 },
          copilot = {
            name = "copilot",
            -- module = "blink-cmp-copilot",
            module = "blink.compat.source",
            score_offset = 100,
            async = true,
            transform_items = function(_, items)
              local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
              local kind_idx = #CompletionItemKind + 1
              CompletionItemKind[kind_idx] = "Copilot"
              for _, item in ipairs(items) do
                item.kind = kind_idx
              end
              return items
            end,
          },
        },
      },
      appearance = {
        -- Blink does not expose its default kind icons so you must copy them all (or set your custom ones) and add Copilot
        kind_icons = {
          Copilot = "",
          Text = "",
          Method = "󰊕",
          Function = "󰊕",
          Constructor = "󰒓",

          Field = "󰜢",
          Variable = "󰆦",
          Property = "󰖷",

          Class = "󱡠",
          Interface = "󱡠",
          Struct = "󱡠",
          Module = "󰅩",

          Unit = "󰪚",
          Value = "󰦨",
          Enum = "󰦨",
          EnumMember = "󰦨",

          Keyword = "󰻾",
          Constant = "󰏿",

          Snippet = "󱄽",
          Color = "󰏘",
          File = "󰈔",
          Reference = "󰬲",
          Folder = "󰉋",
          Event = "󱐋",
          Operator = "󰪚",
          TypeParameter = "󰬛",
        },
      },
      cmdline = {
        enabled = true,
        -- use 'inherit' to inherit mappings from top level `keymap` config
        keymap = { preset = "cmdline" },
        sources = { "buffer", "cmdline" },

        -- OR explicitly configure per cmd type
        -- This ends up being equivalent to above since the sources disable themselves automatically
        -- when not available. You may override their `enabled` functions via
        -- `sources.providers.cmdline.override.enabled = function() return your_logic end`

        -- sources = function()
        --   local type = vim.fn.getcmdtype()
        --   -- Search forward and backward
        --   if type == '/' or type == '?' then return { 'buffer' } end
        --   -- Commands
        --   if type == ':' or type == '@' then return { 'cmdline', 'buffer' } end
        --   return {}
        -- end,

        completion = {
          trigger = {
            show_on_blocked_trigger_characters = {},
            show_on_x_blocked_trigger_characters = {},
          },
          list = {
            selection = {
              -- When `true`, will automatically select the first item in the completion list
              preselect = true,
              -- When `true`, inserts the completion item automatically when selecting it
              auto_insert = true,
            },
          },
          -- Whether to automatically show the window when new completion items are available
          -- Default is false for cmdline, true for cmdwin (command-line window)
          menu = {
            auto_show = function(ctx, _)
              return ctx.mode == "cmdwin"
            end,
          },
          -- Displays a preview of the selected item on the current line
          ghost_text = { enabled = true },
        },
      },
    })
  end,
}
