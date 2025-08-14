-- ::: proof ... ::: -> proof ...
function Div(el)
  if el.classes:includes("box") or el.classes:includes("proof") then
    return el.content
  end
end

-- #xxx {identifier} -> #xxx
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
