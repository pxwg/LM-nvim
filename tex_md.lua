-- ::: proof ... ::: -> proof ...
function Div(el)
  local remove_classes = {
    "box",
    "proof",
    "theorem",
    "lemma",
    "proposition",
    "corollary",
    "definition",
    "remark",
    "example",
    "construction",
    "observation",
  }
  for _, class in ipairs(remove_classes) do
    if el.classes:includes(class) then
      return el.content
    end
  end
end

function Header(el)
  el.identifier = ""
  el.classes = {}
  return el
end

function Math(el)
  if el.mathtype == "DisplayMath" then
    return pandoc.RawInline("markdown", "\n$$\n" .. el.text .. "\n$$\n")
  end
end

-- Make all lists tight (no blank lines between items)
local function tighten_items(items)
  for _, item in ipairs(items) do
    if #item == 1 and item[1].t == "Para" then
      item[1] = pandoc.Plain(item[1].content)
    end
  end
end

function BulletList(el)
  tighten_items(el.content)
  return el
end

function OrderedList(el)
  tighten_items(el.content)
  return el
end
