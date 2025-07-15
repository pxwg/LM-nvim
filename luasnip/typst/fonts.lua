local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local f = ls.function_node
local c = ls.choice_node
local i = ls.insert_node
local d = ls.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local typst = require("util.typst")

-- Helper function to check if we're in a Typst file
local function in_typst()
  return vim.bo.filetype == "typst"
end

local function in_math()
  return typst.in_math()
end

local function not_in_math()
  return not in_math()
end

local get_visual = function(args, parent)
  if #parent.snippet.env.SELECT_RAW > 0 then
    return sn(nil, t(parent.snippet.env.SELECT_RAW))
  else
    return sn(nil, i(1))
  end
end

return {
  -- Text formatting (outside math)
  s(
    {
      trig = "tbf",
      snippetType = "autosnippet",
      wordTrig = true,
    },
    fmta("*<>*<>", { i(1), i(0) }),
    {
      condition = function()
        return in_typst() and not_in_math()
      end,
    }
  ),

  s(
    {
      trig = "tit",
      snippetType = "autosnippet",
      wordTrig = true,
    },
    fmta("_<>_<>", { i(1), i(0) }),
    {
      condition = function()
        return in_typst() and not_in_math()
      end,
    }
  ),

  s(
    {
      trig = "ttt",
      snippetType = "autosnippet",
      wordTrig = true,
    },
    fmta("`<>`<>", { i(1), i(0) }),
    {
      condition = function()
        return in_typst() and not_in_math()
      end,
    }
  ),

  -- Math font commands
  s({
    trig = "mbf",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("bold(<>)<>", { i(1), i(0) }), { condition = in_math }),

  s({
    trig = "mit",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("italic(<>)<>", { i(1), i(0) }), { condition = in_math }),

  s({
    trig = "mrm",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("upright(<>)<>", { i(1), i(0) }), { condition = in_math }),

  s({
    trig = "mtt",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("mono(<>)<>", { i(1), i(0) }), { condition = in_math }),

  -- Calligraphic and script fonts
  s({
    trig = "(%a)cal",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "cal(" .. snip.captures[1]:upper() .. ")"
    end),
  }, { condition = in_math }),

  s({
    trig = "(%a+)cal",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "cal(" .. snip.captures[1]:upper() .. ")"
    end),
  }, { condition = in_math }),

  -- Script font
  s({
    trig = "(%a)scr",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "scripts(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  s({
    trig = "(%a+)scr",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "scripts(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  -- Blackboard bold (double-struck)
  s({
    trig = "(%a)bb",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "bb(" .. snip.captures[1]:upper() .. ")"
    end),
  }, { condition = in_math }),

  s({
    trig = "(%a+)bb",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "bb(" .. snip.captures[1]:upper() .. ")"
    end),
  }, { condition = in_math }),

  -- Fraktur font
  s({
    trig = "(%a)frk",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "frak(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  s({
    trig = "(%a+)frk",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "frak(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  s({
    trig = "(%a+)rm",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "upright(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  -- Sans serif
  s({
    trig = "(%a)sf",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "sans(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  s({
    trig = "(%a+)sf",
    snippetType = "autosnippet",
    wordTrig = true,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "sans(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  -- Text in math mode
  s({
    trig = "txt",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta('upright("<>")<>', { i(1), i(0) }), { condition = in_math }),

  -- Math accents and decorations
  s({
    trig = "(%a+)hat",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "hat(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  s({
    trig = "(%a+)bar",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "overline(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  s({
    trig = "(%a+)tilde",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "tilde(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  s({
    trig = "(%a+)vec",
    snippetType = "autosnippet",
    wordTrig = false,
    regTrig = true,
  }, {
    f(function(_, snip)
      return "arrow(" .. snip.captures[1] .. ")"
    end),
  }, { condition = in_math }),

  -- Size commands
  s({
    trig = "big",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("lr(<>, size: #150%)<>", { i(1), i(0) }), { condition = in_math }),

  s({
    trig = "Big",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("lr(<>, size: #200%)<>", { i(1), i(0) }), { condition = in_math }),

  -- Color commands (though these would require color setup)
  s(
    {
      trig = "red",
      snippetType = "autosnippet",
      wordTrig = true,
    },
    fmta("text(red, <>) <>", { i(1), i(0) }),
    {
      condition = function()
        return in_typst() and not_in_math()
      end,
    }
  ),

  s(
    {
      trig = "blue",
      snippetType = "autosnippet",
      wordTrig = true,
    },
    fmta("text(blue, <>) <>", { i(1), i(0) }),
    {
      condition = function()
        return in_typst() and not_in_math()
      end,
    }
  ),

  s(
    {
      trig = "green",
      snippetType = "autosnippet",
      wordTrig = true,
    },
    fmta("text(green, <>) <>", { i(1), i(0) }),
    {
      condition = function()
        return in_typst() and not_in_math()
      end,
    }
  ),

  -- Math color
  s({
    trig = "mred",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("text(red, $<>$)<>", { i(1), i(0) }), { condition = in_math }),

  s({
    trig = "mblue",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("text(blue, $<>$)<>", { i(1), i(0) }), { condition = in_math }),

  s({
    trig = "mgreen",
    snippetType = "autosnippet",
    wordTrig = true,
  }, fmta("text(green, $<>$)<>", { i(1), i(0) }), { condition = in_math }),
}
