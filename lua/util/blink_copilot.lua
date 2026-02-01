local M = {}

local Source = {}
Source.__index = Source

function Source:get_trigger_characters()
  local success, completion = pcall(require, "CopilotChat.completion")
  if not success then
    return {}
  end

  return completion.info().triggers
end

function Source:get_completions(ctx, callback)
  local success_chat, chat = pcall(require, "CopilotChat")
  if not success_chat then
    callback({ items = {} })
    return
  end

  local _ = chat.initialized

  local success_comp, completion = pcall(require, "CopilotChat.completion")
  local success_async, async = pcall(require, "plenary.async")

  if not success_comp or not success_async then
    callback({ items = {} })
    return
  end

  local line = ctx.line
  local cursor_col = ctx.cursor[2]
  local before_cursor = line:sub(1, cursor_col)
  local info = completion.info()

  local match = vim.fn.matchstrpos(before_cursor, info.pattern)
  local prefix = match and match[1] or ""

  if not prefix or prefix == "" then
    callback({ items = {} })
    return
  end

  async.run(function()
    local items = completion.items()
    return items
  end, function(items)
    local filtered_items = {}
    for _, item in ipairs(items or {}) do
      if item.word and vim.startswith(item.word:lower(), prefix:lower()) then
        table.insert(filtered_items, {
          label = item.word,
          kind = self:convert_kind(item.kind),
          detail = item.menu or "",
          documentation = item.info or "",
          insertText = item.word,
          data = item,
        })
      end
    end

    vim.schedule(function()
      callback({
        items = filtered_items,
        is_incomplete_forward = false,
        is_incomplete_backward = false,
      })
    end)
  end)

  return function() end
end

function Source:convert_kind(kind_str)
  local types = require("blink.cmp.types").CompletionItemKind
  local kind_map = {
    ["user"] = types.Keyword,
    ["system"] = types.Interface,
    ["context"] = types.Reference,
    ["resource"] = types.File,
    ["tool"] = types.Constructor,
    ["github_models"] = types.EnumMember,
    ["group"] = types.Module,
  }

  return kind_map[kind_str] or types.Variable
end

function Source:should_show_completion_item(item, ctx)
  return true
end

function M.new()
  return setmetatable({}, Source)
end

return M
