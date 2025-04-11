-- -- Script to generate mathcal query rules for A-Z and copy to clipboard
-- local mathcal_chars = {
--   a = "𝒜",
--   B = "ℬ",
--   C = "𝒞",
--   D = "𝒟",
--   E = "ℰ",
--   F = "ℱ",
--   G = "𝒢",
--   H = "ℋ",
--   I = "ℐ",
--   J = "𝒥",
--   K = "𝒦",
--   L = "ℒ",
--   M = "ℳ",
--   N = "𝒩",
--   O = "𝒪",
--   P = "𝒫",
--   Q = "𝒬",
--   R = "ℛ",
--   S = "𝒮",
--   T = "𝒯",
--   U = "𝒰",
--   V = "𝒱",
--   W = "𝒲",
--   X = "𝒳",
--   Y = "𝒴",
--   Z = "𝒵",
-- }
--
-- local result = {}
-- for letter, unicode in pairs(mathcal_chars) do
--   table.insert(
--     result,
--     string.format(
--       '((generic_command) @mathcal_%s\n  (#match? @mathcal_%s "\\\\\\\\mathcal\\\\{%s\\\\}")\n  (#set! conceal "%s"))',
--       letter,
--       letter,
--       letter,
--       unicode
--     )
--   )
-- end
--
-- local output = table.concat(result, "\n\n")

-- -- Copy to clipboard
-- local handle = io.popen("pbcopy", "w")
-- handle:write(output)
-- handle:close()

-- print("Generated mathcal query rules for A-Z and copied to clipboard!")

local M = {}

 function
 M.["convert_to_mathcal"](arg)
  print("Converting to mathcal: " .. arg)
end
return M
