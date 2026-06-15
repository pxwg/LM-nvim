local function raw_fence(text, minimum)
  local fence = string.rep("`", minimum or 3)
  while text:find(fence, 1, true) do
    fence = fence .. "`"
  end
  return fence
end

local function inline_mitex(text)
  local fence = raw_fence(text, 3)
  return "#mitex(" .. fence .. text .. fence .. ")"
end

local function block_mitex(text)
  local fence = raw_fence(text, 3)
  return table.concat({
    "#mitex(",
    fence,
    text,
    fence,
    ")",
  }, "\n")
end

local function is_display_math(el)
  return el and el.t == "Math" and el.mathtype == "DisplayMath"
end

local function display_math_block(el)
  if #el.content == 1 and is_display_math(el.content[1]) then
    return pandoc.RawBlock("typst", block_mitex(el.content[1].text))
  end
end

return {
  {
    traverse = "topdown",

    Para = display_math_block,

    Plain = display_math_block,

    Math = function(el)
      if el.mathtype == "DisplayMath" then
        return pandoc.RawInline("typst", block_mitex(el.text))
      end

      return pandoc.RawInline("typst", inline_mitex(el.text))
    end,
  },
}
