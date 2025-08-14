function Div(el)
  if el.classes:includes("box") then
    return el.content
  end
end

function Math(el)
  if el.mathtype == "DisplayMath" then
    return pandoc.RawInline("markdown", "\n$$\n" .. el.text .. "\n$$\n")
  end
end
