-- Script to generate mathfrak query rules for A-Z, a-z and write to file
local mathfrak_chars = {
  -- Uppercase
  A = "𝔄",
  B = "𝔅",
  C = "ℭ",
  D = "𝔇",
  E = "𝔈",
  F = "𝔉",
  G = "𝔊",
  H = "ℌ",
  I = "ℑ",
  J = "𝔍",
  K = "𝔎",
  L = "𝔏",
  M = "𝔐",
  N = "𝔑",
  O = "𝔒",
  P = "𝔓",
  Q = "𝔔",
  R = "ℜ",
  S = "𝔖",
  T = "𝔗",
  U = "𝔘",
  V = "𝔙",
  W = "𝔚",
  X = "𝔛",
  Y = "𝔜",
  Z = "ℨ",
  -- Lowercase
  a = "𝔞",
  b = "𝔟",
  c = "𝔠",
  d = "𝔡",
  e = "𝔢",
  f = "𝔣",
  g = "𝔤",
  h = "𝔥",
  i = "𝔦",
  j = "𝔧",
  k = "𝔨",
  l = "𝔩",
  m = "𝔪",
  n = "𝔫",
  o = "𝔬",
  p = "𝔭",
  q = "𝔮",
  r = "𝔯",
  s = "𝔰",
  t = "𝔱",
  u = "𝔲",
  v = "𝔳",
  w = "𝔴",
  x = "𝔵",
  y = "𝔶",
  z = "𝔷",
}

local result = {}
for letter, unicode in pairs(mathfrak_chars) do
  table.insert(
    result,
    string.format(
      '((generic_command) @mathfrak_%s\n  (#match? @mathfrak_%s "\\\\\\\\mathfrak\\\\{%s\\\\}")\n  (#set! conceal "%s"))',
      letter,
      letter,
      letter,
      unicode
    )
  )
end

local output = table.concat(result, "\n\n")
print(output)

-- Write to file instead of copying to clipboard
local handle = io.popen(vim.fn.stdpath("config") .. "/queries/latex/mathfrak.scm", "w")
if handle then
  handle:write(output)
  handle:close()
  print(
    "Generated mathfrak query rules for A-Z, a-z and saved to "
      .. vim.fn.stdpath("config")
      .. "/queries/latex/mathfrak.scm"
  )
else
  print("Error: Could not open file for writing")
end
