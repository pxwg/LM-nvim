local M = {}
local math_font_table = setmetatable({
  ["\\mathbb{A}"] = "𝔸",
  ["\\mathbb{B}"] = "𝔹",
  ["\\mathbb{C}"] = "ℂ",
  ["\\mathbb{D}"] = "𝔻",
  ["\\mathbb{E}"] = "𝔼",
  ["\\mathbb{F}"] = "𝔽",
  ["\\mathbb{G}"] = "𝔾",
  ["\\mathbb{H}"] = "ℍ",
  ["\\mathbb{I}"] = "𝕀",
  ["\\mathbb{J}"] = "𝕁",
  ["\\mathbb{K}"] = "𝕂",
  ["\\mathbb{L}"] = "𝕃",
  ["\\mathbb{M}"] = "𝕄",
  ["\\mathbb{N}"] = "ℕ",
  ["\\mathbb{O}"] = "𝕆",
  ["\\mathbb{P}"] = "ℙ",
  ["\\mathbb{Q}"] = "ℚ",
  ["\\mathbb{R}"] = "ℝ",
  ["\\mathbb{S}"] = "𝕊",
  ["\\mathbb{T}"] = "𝕋",
  ["\\mathbb{U}"] = "𝕌",
  ["\\mathbb{V}"] = "𝕍",
  ["\\mathbb{W}"] = "𝕎",
  ["\\mathbb{X}"] = "𝕏",
  ["\\mathbb{Y}"] = "𝕐",
  ["\\mathbb{Z}"] = "ℤ",
  ["\\mathsf{a}"] = "𝖺",
  ["\\mathsf{b}"] = "𝖻",
  ["\\mathsf{c}"] = "𝖼",
  ["\\mathsf{d}"] = "𝖽",
  ["\\mathsf{e}"] = "𝖾",
  ["\\mathsf{f}"] = "𝖿",
  ["\\mathsf{g}"] = "𝗀",
  ["\\mathsf{h}"] = "𝗁",
  ["\\mathsf{i}"] = "𝗂",
  ["\\mathsf{j}"] = "𝗃",
  ["\\mathsf{k}"] = "𝗄",
  ["\\mathsf{l}"] = "𝗅",
  ["\\mathsf{m}"] = "𝗆",
  ["\\mathsf{n}"] = "𝗇",
  ["\\mathsf{o}"] = "𝗈",
  ["\\mathsf{p}"] = "𝗉",
  ["\\mathsf{q}"] = "𝗊",
  ["\\mathsf{r}"] = "𝗋",
  ["\\mathsf{s}"] = "𝗌",
  ["\\mathsf{t}"] = "𝗍",
  ["\\mathsf{u}"] = "𝗎",
  ["\\mathsf{v}"] = "𝗏",
  ["\\mathsf{w}"] = "𝗐",
  ["\\mathsf{x}"] = "𝗑",
  ["\\mathsf{y}"] = "𝗒",
  ["\\mathsf{z}"] = "𝗓",
  ["\\mathsf{A}"] = "𝖠",
  ["\\mathsf{B}"] = "𝖡",
  ["\\mathsf{C}"] = "𝖢",
  ["\\mathsf{D}"] = "𝖣",
  ["\\mathsf{E}"] = "𝖤",
  ["\\mathsf{F}"] = "𝖥",
  ["\\mathsf{G}"] = "𝖦",
  ["\\mathsf{H}"] = "𝖧",
  ["\\mathsf{I}"] = "𝖨",
  ["\\mathsf{J}"] = "𝖩",
  ["\\mathsf{K}"] = "𝖪",
  ["\\mathsf{L}"] = "𝖫",
  ["\\mathsf{M}"] = "𝖬",
  ["\\mathsf{N}"] = "𝖭",
  ["\\mathsf{O}"] = "𝖮",
  ["\\mathsf{P}"] = "𝖯",
  ["\\mathsf{Q}"] = "𝖰",
  ["\\mathsf{R}"] = "𝖱",
  ["\\mathsf{S}"] = "𝖲",
  ["\\mathsf{T}"] = "𝖳",
  ["\\mathsf{U}"] = "𝖴",
  ["\\mathsf{V}"] = "𝖵",
  ["\\mathsf{W}"] = "𝖶",
  ["\\mathsf{X}"] = "𝖷",
  ["\\mathsf{Y}"] = "𝖸",
  ["\\mathsf{Z}"] = "𝖹",
  ["\\mathfrak{a}"] = "𝔞",
  ["\\mathfrak{b}"] = "𝔟",
  ["\\mathfrak{c}"] = "𝔠",
  ["\\mathfrak{d}"] = "𝔡",
  ["\\mathfrak{e}"] = "𝔢",
  ["\\mathfrak{f}"] = "𝔣",
  ["\\mathfrak{g}"] = "𝔤",
  ["\\mathfrak{h}"] = "𝔥",
  ["\\mathfrak{i}"] = "𝔦",
  ["\\mathfrak{j}"] = "𝔧",
  ["\\mathfrak{k}"] = "𝔨",
  ["\\mathfrak{l}"] = "𝔩",
  ["\\mathfrak{m}"] = "𝔪",
  ["\\mathfrak{n}"] = "𝔫",
  ["\\mathfrak{o}"] = "𝔬",
  ["\\mathfrak{p}"] = "𝔭",
  ["\\mathfrak{q}"] = "𝔮",
  ["\\mathfrak{r}"] = "𝔯",
  ["\\mathfrak{s}"] = "𝔰",
  ["\\mathfrak{t}"] = "𝔱",
  ["\\mathfrak{u}"] = "𝔲",
  ["\\mathfrak{v}"] = "𝔳",
  ["\\mathfrak{w}"] = "𝔴",
  ["\\mathfrak{x}"] = "𝔵",
  ["\\mathfrak{y}"] = "𝔶",
  ["\\mathfrak{z}"] = "𝔷",
  ["\\mathfrak{A}"] = "𝔄",
  ["\\mathfrak{B}"] = "𝔅",
  ["\\mathfrak{C}"] = "ℭ",
  ["\\mathfrak{D}"] = "𝔇",
  ["\\mathfrak{E}"] = "𝔈",
  ["\\mathfrak{F}"] = "𝔉",
  ["\\mathfrak{G}"] = "𝔊",
  ["\\mathfrak{H}"] = "ℌ",
  ["\\mathfrak{I}"] = "ℑ",
  ["\\mathfrak{J}"] = "𝔍",
  ["\\mathfrak{K}"] = "𝔎",
  ["\\mathfrak{L}"] = "𝔏",
  ["\\mathfrak{M}"] = "𝔐",
  ["\\mathfrak{N}"] = "𝔑",
  ["\\mathfrak{O}"] = "𝔒",
  ["\\mathfrak{P}"] = "𝔓",
  ["\\mathfrak{Q}"] = "𝔔",
  ["\\mathfrak{R}"] = "ℜ",
  ["\\mathfrak{S}"] = "𝔖",
  ["\\mathfrak{T}"] = "𝔗",
  ["\\mathfrak{U}"] = "𝔘",
  ["\\mathfrak{V}"] = "𝔙",
  ["\\mathfrak{W}"] = "𝔚",
  ["\\mathfrak{X}"] = "𝔛",
  ["\\mathfrak{Y}"] = "𝔜",
  ["\\mathfrak{Z}"] = "ℨ",
  ["\\mathscr{A}"] = "𝓐",
  ["\\mathscr{B}"] = "𝓑",
  ["\\mathscr{C}"] = "𝓒",
  ["\\mathscr{D}"] = "𝓓",
  ["\\mathscr{E}"] = "𝓔",
  ["\\mathscr{F}"] = "𝓕",
  ["\\mathscr{G}"] = "𝓖",
  ["\\mathscr{H}"] = "𝓗",
  ["\\mathscr{I}"] = "𝓘",
  ["\\mathscr{J}"] = "𝓙",
  ["\\mathscr{K}"] = "𝓚",
  ["\\mathscr{L}"] = "𝓛",
  ["\\mathscr{M}"] = "𝓜",
  ["\\mathscr{N}"] = "𝓝",
  ["\\mathscr{O}"] = "𝓞",
  ["\\mathscr{P}"] = "𝓟",
  ["\\mathscr{Q}"] = "𝓠",
  ["\\mathscr{R}"] = "𝓡",
  ["\\mathscr{S}"] = "𝓢",
  ["\\mathscr{T}"] = "𝓣",
  ["\\mathscr{U}"] = "𝓤",
  ["\\mathscr{V}"] = "𝓥",
  ["\\mathscr{W}"] = "𝓦",
  ["\\mathscr{X}"] = "𝓧",
  ["\\mathscr{Y}"] = "𝓨",
  ["\\mathscr{Z}"] = "𝓩",
  ["\\mathcal{A}"] = "𝓐",
  ["\\mathcal{B}"] = "𝓑",
  ["\\mathcal{C}"] = "𝓒",
  ["\\mathcal{D}"] = "𝓓",
  ["\\mathcal{E}"] = "𝓔",
  ["\\mathcal{F}"] = "𝓕",
  ["\\mathcal{G}"] = "𝓖",
  ["\\mathcal{H}"] = "𝓗",
  ["\\mathcal{I}"] = "𝓘",
  ["\\mathcal{J}"] = "𝓙",
  ["\\mathcal{K}"] = "𝓚",
  ["\\mathcal{L}"] = "𝓛",
  ["\\mathcal{M}"] = "𝓜",
  ["\\mathcal{N}"] = "𝓝",
  ["\\mathcal{O}"] = "𝓞",
  ["\\mathcal{P}"] = "𝓟",
  ["\\mathcal{Q}"] = "𝓠",
  ["\\mathcal{R}"] = "𝓡",
  ["\\mathcal{S}"] = "𝓢",
  ["\\mathcal{T}"] = "𝓣",
  ["\\mathcal{U}"] = "𝓤",
  ["\\mathcal{V}"] = "𝓥",
  ["\\mathcal{W}"] = "𝓦",
  ["\\mathcal{X}"] = "𝓧",
  ["\\mathcal{Y}"] = "𝓨",
  ["\\mathcal{Z}"] = "𝓩",
  ["\\alpha"] = "α",
  ["\\beta"] = "β",
  ["\\gamma"] = "γ",
  ["\\delta"] = "δ",
  ["\\epsilon"] = "ϵ",
  ["\\varepsilon"] = "ε",
  ["\\zeta"] = "ζ",
  ["\\eta"] = "η",
  ["\\theta"] = "θ",
  ["\\vartheta"] = "ϑ",
  ["\\iota"] = "ι",
  ["\\kappa"] = "κ",
  ["\\lambda"] = "λ",
  ["\\mu"] = "μ",
  ["\\nu"] = "ν",
  ["\\xi"] = "ξ",
  ["\\pi"] = "π",
  ["\\varpi"] = "ϖ",
  ["\\rho"] = "ρ",
  ["\\varrho"] = "ϱ",
  ["\\sigma"] = "σ",
  ["\\varsigma"] = "ς",
  ["\\tau"] = "τ",
  ["\\upsilon"] = "υ",
  ["\\phi"] = "ϕ",
  ["\\varphi"] = "φ",
  ["\\chi"] = "χ",
  ["\\psi"] = "ψ",
  ["\\omega"] = "ω",
  ["\\Gamma"] = "Γ",
  ["\\Delta"] = "Δ",
  ["\\Theta"] = "Θ",
  ["\\Lambda"] = "Λ",
  ["\\Xi"] = "Ξ",
  ["\\Pi"] = "Π",
  ["\\Sigma"] = "Σ",
  ["\\Upsilon"] = "Υ",
  ["\\Phi"] = "Φ",
  ["\\Chi"] = "Χ",
  ["\\Psi"] = "Ψ",
  ["\\Omega"] = "Ω",
  ["\\|"] = "‖",
  ["\\amalg"] = "∐",
  ["\\angle"] = "∠",
  ["\\approx"] = "≈",
  ["\\ast"] = "∗",
  ["\\asymp"] = "≍",
  ["\\backslash"] = "∖",
  ["\\bigcap"] = "∩",
  ["\\bigcirc"] = "○",
  ["\\bigcup"] = "∪",
  ["\\bigodot"] = "⊙",
  ["\\bigoplus"] = "⊕",
  ["\\bigotimes"] = "⊗",
  ["\\bigsqcup"] = "⊔",
  ["\\bigtriangledown"] = "∇",
  ["\\bigtriangleup"] = "∆",
  ["\\bigvee"] = "⋁",
  ["\\bigwedge"] = "⋀",
  ["\\bot"] = "⊥",
  ["\\bowtie"] = "⋈",
  ["\\bullet"] = "•",
  ["\\cap"] = "∩",
  ["\\cdot"] = "·",
  ["\\cdots"] = "⋯",
  ["\\circ"] = "∘",
  ["\\cong"] = "≅",
  ["\\coprod"] = "∐",
  ["\\copyright"] = "©",
  ["\\cup"] = "∪",
  ["\\dagger"] = "†",
  ["\\dashv"] = "⊣",
  ["\\ddagger"] = "‡",
  ["\\ddots"] = "⋱",
  ["\\diamond"] = "⋄",
  ["\\div"] = "÷",
  ["\\doteq"] = "≐",
  ["\\dots"] = "…",
  ["\\downarrow"] = "↓",
  ["\\Downarrow"] = "⇓",
  ["\\equiv"] = "≡",
  ["\\exists"] = "∃",
  ["\\flat"] = "♭",
  ["\\forall"] = "∀",
  ["\\frown"] = "⁔",
  ["\\ge"] = "≥",
  ["\\geq"] = "≥",
  ["\\gets"] = "←",
  ["\\gg"] = "⟫",
  ["\\hookleftarrow"] = "↩",
  ["\\hookrightarrow"] = "↪",
  ["\\iff"] = "⇔",
  ["\\Im"] = "ℑ",
  ["\\in"] = "∈",
  ["\\int"] = "∫",
  ["\\jmath"] = "𝚥",
  ["\\land"] = "∧",
  ["\\lceil"] = "⌈",
  ["\\ldots"] = "…",
  ["\\le"] = "≤",
  ["\\left"] = "",
  ["\\leftarrow"] = "←",
  ["\\Leftarrow"] = "⇐",
  ["\\leftharpoondown"] = "↽",
  ["\\leftharpoonup"] = "↼",
  ["\\leftrightarrow"] = "↔",
  ["\\Leftrightarrow"] = "⇔",
  ["\\leq"] = "≤",
  ["\\lfloor"] = "⌊",
  ["\\ll"] = "≪",
  ["\\lmoustache"] = "╭",
  ["\\lor"] = "∨",
  ["\\mapsto"] = "↦",
  ["\\mid"] = "∣",
  ["\\models"] = "╞",
  ["\\mp"] = "∓",
  ["\\nabla"] = "∇",
  ["\\natural"] = "♮",
  ["\\ne"] = "≠",
  ["\\nearrow"] = "↗",
  ["\\neg"] = "¬",
  ["\\neq"] = "≠",
  ["\\ni"] = "∋",
  ["\\notin"] = "∉",
  ["\\nwarrow"] = "↖",
  ["\\odot"] = "⊙",
  ["\\oint"] = "∮",
  ["\\ominus"] = "⊖",
  ["\\oplus"] = "⊕",
  ["\\oslash"] = "⊘",
  ["\\otimes"] = "⊗",
  ["\\owns"] = "∋",
  ["\\P"] = "¶",
  ["\\parallel"] = "║",
  ["\\partial"] = "∂",
  ["\\perp"] = "⊥",
  ["\\pm"] = "±",
  ["\\prec"] = "≺",
  ["\\preceq"] = "⪯",
  ["\\prime"] = "′",
  ["\\prod"] = "∏",
  ["\\propto"] = "∝",
  ["\\rceil"] = "⌉",
  ["\\Re"] = "ℜ",
  ["\\quad"] = " ",
  ["\\qquad"] = " ",
  ["\\rfloor"] = "⌋",
  ["\\right"] = "",
  ["\\rightarrow"] = "→",
  ["\\Rightarrow"] = "⇒",
  ["\\rightleftharpoons"] = "⇌",
  ["\\rmoustache"] = "╮",
  ["\\S"] = "§",
  ["\\searrow"] = "↘",
  ["\\setminus"] = "∖",
  ["\\sharp"] = "♯",
  ["\\sim"] = "∼",
  ["\\simeq"] = "⋍",
  ["\\smile"] = "‿",
  ["\\sqcap"] = "⊓",
  ["\\sqcup"] = "⊔",
  ["\\sqsubset"] = "⊏",
  ["\\sqsubseteq"] = "⊑",
  ["\\sqsupset"] = "⊐",
  ["\\sqsupseteq"] = "⊒",
  ["\\star"] = "✫",
  ["\\subset"] = "⊂",
  ["\\subseteq"] = "⊆",
  ["\\succ"] = "≻",
  ["\\succeq"] = "⪰",
  ["\\sum"] = "∑",
  ["\\supset"] = "⊃",
  ["\\supseteq"] = "⊇",
  ["\\surd"] = "√",
  ["\\swarrow"] = "↙",
  ["\\times"] = "×",
  ["\\to"] = "→",
  ["\\top"] = "⊤",
  ["\\triangle"] = "∆",
  ["\\triangleleft"] = "⊲",
  ["\\triangleright"] = "⊳",
  ["\\uparrow"] = "↑",
  ["\\Uparrow"] = "⇑",
  ["\\updownarrow"] = "↕",
  ["\\Updownarrow"] = "⇕",
  ["\\vdash"] = "⊢",
  ["\\vdots"] = "⋮",
  ["\\vee"] = "∨",
  ["\\wedge"] = "∧",
  ["\\wp"] = "℘",
  ["\\wr"] = "≀",
  ["\\langle"] = "⟨",
  ["\\rangle"] = "⟩",
  ["\\{"] = "{",
  ["\\}"] = "}",
  ["\\aleph"] = "ℵ",
  ["\\clubsuit"] = "♣",
  ["\\diamondsuit"] = "♢",
  ["\\heartsuit"] = "♡",
  ["\\spadesuit"] = "♠",
  ["\\ell"] = "ℓ",
  ["\\emptyset"] = "∅",
  ["\\varnothing"] = "∅",
  ["\\hbar"] = "ℏ",
  ["\\imath"] = "ɩ",
  ["\\infty"] = "∞",
  ["_0"] = "₀",
  ["_1"] = "₁",
  ["_2"] = "₂",
  ["_3"] = "₃",
  ["_4"] = "₄",
  ["_5"] = "₅",
  ["_6"] = "₆",
  ["_7"] = "₇",
  ["_8"] = "₈",
  ["_9"] = "₉",
  ["_a"] = "ₐ",
  ["_e"] = "ₑ",
  ["_h"] = "ₕ",
  ["_i"] = "ᵢ",
  ["_j"] = "ⱼ",
  ["_k"] = "ₖ",
  ["_l"] = "ₗ",
  ["_m"] = "ₘ",
  ["_n"] = "ₙ",
  ["_o"] = "ₒ",
  ["_p"] = "ₚ",
  ["_r"] = "ᵣ",
  ["_s"] = "ₛ",
  ["_t"] = "ₜ",
  ["_u"] = "ᵤ",
  ["_v"] = "ᵥ",
  ["_x"] = "ₓ",
  ["_\\."] = "‸",
  ["_+"] = "₊",
  ["_-"] = "₋",
  ["_/"] = "ˏ",
  ["0"] = "₀",
  ["1"] = "₁",
  ["2"] = "₂",
  ["3"] = "₃",
  ["4"] = "₄",
  ["5"] = "₅",
  ["6"] = "₆",
  ["7"] = "₇",
  ["8"] = "₈",
  ["9"] = "₉",
  ["a"] = "ₐ",
  ["e"] = "ₑ",
  ["h"] = "ₕ",
  ["i"] = "ᵢ",
  ["j"] = "ⱼ",
  ["k"] = "ₖ",
  ["l"] = "ₗ",
  ["m"] = "ₘ",
  ["n"] = "ₙ",
  ["o"] = "ₒ",
  ["p"] = "ₚ",
  ["r"] = "ᵣ",
  ["s"] = "ₛ",
  ["t"] = "ₜ",
  ["u"] = "ᵤ",
  ["v"] = "ᵥ",
  ["x"] = "ₓ",
  ["+"] = "₊",
  ["-"] = "₋",
  ["/"] = "ˏ",

  -- Superscripts with caret prefix
  ["^0"] = "⁰",
  ["^1"] = "¹",
  ["^2"] = "²",
  ["^3"] = "³",
  ["^4"] = "⁴",
  ["^5"] = "⁵",
  ["^6"] = "⁶",
  ["^7"] = "⁷",
  ["^8"] = "⁸",
  ["^9"] = "⁹",
  ["^a"] = "ᵃ",
  ["^b"] = "ᵇ",
  ["^c"] = "ᶜ",
  ["^d"] = "ᵈ",
  ["^e"] = "ᵉ",
  ["^f"] = "ᶠ",
  ["^g"] = "ᵍ",
  ["^h"] = "ʰ",
  ["^i"] = "ⁱ",
  ["^j"] = "ʲ",
  ["^k"] = "ᵏ",
  ["^l"] = "ˡ",
  ["^m"] = "ᵐ",
  ["^n"] = "ⁿ",
  ["^o"] = "ᵒ",
  ["^p"] = "ᵖ",
  ["^r"] = "ʳ",
  ["^s"] = "ˢ",
  ["^t"] = "ᵗ",
  ["^u"] = "ᵘ",
  ["^v"] = "ᵛ",
  ["^w"] = "ʷ",
  ["^x"] = "ˣ",
  ["^y"] = "ʸ",
  ["^z"] = "ᶻ",
  ["^A"] = "ᴬ",
  ["^B"] = "ᴮ",
  ["^D"] = "ᴰ",
  ["^E"] = "ᴱ",
  ["^G"] = "ᴳ",
  ["^H"] = "ᴴ",
  ["^I"] = "ᴵ",
  ["^J"] = "ᴶ",
  ["^K"] = "ᴷ",
  ["^L"] = "ᴸ",
  ["^M"] = "ᴹ",
  ["^N"] = "ᴺ",
  ["^O"] = "ᴼ",
  ["^P"] = "ᴾ",
  ["^R"] = "ᴿ",
  ["^T"] = "ᵀ",
  ["^U"] = "ᵁ",
  ["^V"] = "ⱽ",
  ["^W"] = "ᵂ",
  ["^+"] = "⁺",
  ["^-"] = "⁻",
  ["^<"] = "˂",
  ["^>"] = "˃",
  ["^/"] = "ˊ",
  ["^\\."] = "˙",
  ["^="] = "˭",
}, {
  __index = function()
    return ""
  end,
})
M.math_font_table = math_font_table

return M
