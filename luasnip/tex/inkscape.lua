local fmta = require("luasnip.extras.fmt").fmta
local ls = require("luasnip")
local d = ls.dynamic_node
local s = ls.snippet
local t = ls.text_node
local f = ls.function_node
local i = ls.insert_node
local sn = ls.snippet_node
local tex = require("util.latex")

local get_visual = function(args, parent)
  if #parent.snippet.env.SELECT_RAW > 0 then
    return sn(nil, t(parent.snippet.env.SELECT_RAW))
  else -- If SELECT_RAW is empty, return a blank insert node
    return sn(nil, i(1))
  end
end

-- need fig_name

local function exec_terminal_command(filename)
  local dir_path = vim.fn.expand("~/Desktop/physics/figure/")
  local file_path = dir_path .. filename .. ".svg"
  local file_exists = false

  -- 遍历目录中的所有文件
  for _, file in ipairs(vim.fn.readdir(dir_path)) do
    if file == filename .. ".svg" then
      file_exists = true
      break
    end
  end

  -- 如果文件不存在，则创建新文件
  if not file_exists then
    vim.fn.system(
      string.format(
        [[echo '<svg width="1920" height="1080" xmlns="http://www.w3.org/2000/svg"></svg>' > %s]],
        file_path
      )
    )
  end

  -- 使用Inkscape打开文件
  vim.fn.system(string.format(
    [[osascript -e '
    tell application "Inkscape"
        activate
        open POSIX file "%s"
    end tell
    ']],
    file_path
  ))

  -- 检查是否存在第二个显示器
  local displays = vim.fn.systemlist("system_profiler SPDisplaysDataType | grep 'Resolution'")
  local second_monitor_exists = false

  for _, display in ipairs(displays) do
    if string.match(display, "Resolution: 2388 x 1668") then
      second_monitor_exists = true
      break
    end
  end

  if second_monitor_exists then
    -- 使用 SizeUp 将窗口移动到第二个显示器
    vim.fn.system([[
      osascript -e '
      tell application "SizeUp"
          send to monitor 2
      end tell
      '
    ]])
  end

  -- 全屏显示 Inkscape 窗口
  vim.fn.system([[
    osascript -e '
    tell application "System Events"
        tell process "Inkscape"
            set value of attribute "AXFullScreen" of window 1 to true
        end tell
    end tell
    '
  ]])

  vim.cmd("redraw!")
end

return {

  s(
    { trig = "inkfig", wordTrig = false, snippetType = "autosnippet" },
    fmta("fig <> fig", {
      d(1, get_visual),
    }),
    {}
  ),
  s(
    { trig = "fig.*figs", snippetType = "autosnippet", regTrig = true },
    d(1, function(_, parent)
      local filename = string.gsub(parent.trigger, "^fig(.*)figs", "%1")
      filename = string.gsub(filename, "^%s+(.*)%s+$", "%1")
      exec_terminal_command(filename)
      return sn(nil, t("\\incfig{" .. filename .. "}"))
    end, {}),
    { condition = tex.in_figure }
  ),
}
