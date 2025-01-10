require("utils.rime_blinks")
return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  enabled = true,
  -- use a release tag to download pre-built binaries
  version = "*",
  -- enabled = true,
  build = "cargo build --release",
  dependencies = {
    -- add source
    {
      "zbirenbaum/copilot-cmp",
      "zbirenbaum/copilot.lua",
      "dmitmel/cmp-digraphs",
      "L3MON4D3/LuaSnip",
      "mikavilpas/blink-ripgrep.nvim",
      "giuxtaposition/blink-cmp-copilot",
      {
        "saghen/blink.compat",
        opts = { impersonate_nvim_cmp = true, enable_events = true },
      },
      -- "zbirenbaum/copilot-cmp",
    },
  },
  -- build = 'cargo build --release',
  config = function()
    -- if last char is number, and the only completion item is provided by rime-ls, accept it
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
      set_hl("BlinkCmpKind" .. kind, { link = "CmpItemKind" .. kind or "BlinkCmpKind" })
    end

    vim.api.nvim_create_autocmd("User", {
      pattern = "BlinkCmpMenuOpen",
      callback = function()
        require("copilot.suggestion").dismiss()
        vim.b.copilot_suggestion_hidden = true
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "BlinkCmpMenuClose",
      callback = function()
        vim.b.copilot_suggestion_hidden = false
      end,
    })

    require("copilot_cmp").setup()
    require("blink.cmp").setup({
      keymap = {
        preset = "none",
        ["<cr>"] = { "accept", "fallback" },
        -- ["<tab>"] = { "snippet_forward", "fallback" },
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
        [";"] = {
          -- FIX: can not work when binding ;<space> to other key
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
      completion = {
        ghost_text = { enabled = true },
        documentation = {
          auto_show = true,
          window = {
            min_width = 10,
            max_width = 80,
            max_height = 20,
            border = { "󱕦", "─", "󰄛", "│", "", "─", "󰩃", "│" },
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
          -- auto_show = true,
          draw = {
            columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
          },
          border = { "󱕦", "─", "󰄛", "│", "", "─", "󰩃", "│" },
          winhighlight = "FloatBorder:CmpBorder",
          -- winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel,FloatBorder:CmpBorder",
        },
      },
      snippets = { preset = "luasnip" },
      fuzzy = { use_typo_resistance = true, use_proximity = false, use_frecency = false, use_unsafe_no_lock = true },
      sources = {
        default = { "lsp", "path", "buffer", "copilot" },
        cmdline = {},
        providers = {
          lsp = {
            min_keyword_length = 0,
            fallbacks = { "ripgrep", "buffer" },
            --- @param items blink.cmp.CompletionItem[]
            transform_items = function(_, items)
              -- demote snippets
              for _, item in ipairs(items) do
                -- if item.kind == require("blink.cmp.types").CompletionItemKind.Snippet then
                --   item.score_offset = item.score_offset - 3
                -- end
                if item.kind == require("blink.cmp.types").CompletionItemKind.Text then
                  item.score_offset = item.score_offset + 2
                end
              end
              return items
            end,
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
          Text = "󰉿",
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
    })
  end,
}
