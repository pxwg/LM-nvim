; extends

; Conceal the command part
((command_name) @_cmd
  (#any-of? @_cmd "\\mathrm" "\\mathit" "\\textit" "\\mathbf" "\\textbf" "\\emph")
  (#set! conceal ""))

; Conceal the opening brace
((generic_command
  command: (command_name) @_cmd
  arg: (curly_group
    "{" @_open_brace))
  (#any-of? @_cmd "\\mathrm" "\\mathit" "\\textit" "\\mathbf" "\\textbf" "\\emph")
  (#set! @_open_brace conceal ""))

; Conceal the closing brace
((generic_command
  command: (command_name) @_cmd
  arg: (curly_group
    "}" @_close_brace))
  (#any-of? @_cmd "\\mathrm" "\\mathit" "\\textit" "\\mathbf" "\\textbf" "\\emph")
  (#set! @_close_brace conceal ""))

;
; Mathbb fonts
((generic_command) @mathbb_symbol
  (#match? @mathbb_symbol "\\\\mathbb\\{([A-Z])\\}")
  (#set! conceal ""))

((generic_command) @mathbb_A
  (#match? @mathbb_A "\\\\mathbb\\{A\\}")
  (#set! conceal "𝔸"))

((generic_command) @mathbb_B
  (#match? @mathbb_B "\\\\mathbb\\{B\\}")
  (#set! conceal "𝔹"))

((generic_command) @mathbb_C
  (#match? @mathbb_C "\\\\mathbb\\{C\\}")
  (#set! conceal "ℂ"))

((generic_command) @mathbb_D
  (#match? @mathbb_D "\\\\mathbb\\{D\\}")
  (#set! conceal "𝔻"))

((generic_command) @mathbb_E
  (#match? @mathbb_E "\\\\mathbb\\{E\\}")
  (#set! conceal "𝔼"))

((generic_command) @mathbb_F
  (#match? @mathbb_F "\\\\mathbb\\{F\\}")
  (#set! conceal "𝔽"))

((generic_command) @mathbb_G
  (#match? @mathbb_G "\\\\mathbb\\{G\\}")
  (#set! conceal "𝔾"))

((generic_command) @mathbb_H
  (#match? @mathbb_H "\\\\mathbb\\{H\\}")
  (#set! conceal "ℍ"))

((generic_command) @mathbb_I
  (#match? @mathbb_I "\\\\mathbb\\{I\\}")
  (#set! conceal "𝕀"))

((generic_command) @mathbb_J
  (#match? @mathbb_J "\\\\mathbb\\{J\\}")
  (#set! conceal "𝕁"))

((generic_command) @mathbb_K
  (#match? @mathbb_K "\\\\mathbb\\{K\\}")
  (#set! conceal "𝕂"))

((generic_command) @mathbb_L
  (#match? @mathbb_L "\\\\mathbb\\{L\\}")
  (#set! conceal "𝕃"))

((generic_command) @mathbb_M
  (#match? @mathbb_M "\\\\mathbb\\{M\\}")
  (#set! conceal "𝕄"))

((generic_command) @mathbb_N
  (#match? @mathbb_N "\\\\mathbb\\{N\\}")
  (#set! conceal "ℕ"))

((generic_command) @mathbb_O
  (#match? @mathbb_O "\\\\mathbb\\{O\\}")
  (#set! conceal "𝕆"))

((generic_command) @mathbb_P
  (#match? @mathbb_P "\\\\mathbb\\{P\\}")
  (#set! conceal "ℙ"))

((generic_command) @mathbb_Q
  (#match? @mathbb_Q "\\\\mathbb\\{Q\\}")
  (#set! conceal "ℚ"))

((generic_command) @mathbb_R
  (#match? @mathbb_R "\\\\mathbb\\{R\\}")
  (#set! conceal "ℝ"))

((generic_command) @mathbb_S
  (#match? @mathbb_S "\\\\mathbb\\{S\\}")
  (#set! conceal "𝕊"))

((generic_command) @mathbb_T
  (#match? @mathbb_T "\\\\mathbb\\{T\\}")
  (#set! conceal "𝕋"))

((generic_command) @mathbb_U
  (#match? @mathbb_U "\\\\mathbb\\{U\\}")
  (#set! conceal "𝕌"))

((generic_command) @mathbb_V
  (#match? @mathbb_V "\\\\mathbb\\{V\\}")
  (#set! conceal "𝕍"))

((generic_command) @mathbb_W
  (#match? @mathbb_W "\\\\mathbb\\{W\\}")
  (#set! conceal "𝕎"))

((generic_command) @mathbb_X
  (#match? @mathbb_X "\\\\mathbb\\{X\\}")
  (#set! conceal "𝕏"))

((generic_command) @mathbb_Y
  (#match? @mathbb_Y "\\\\mathbb\\{Y\\}")
  (#set! conceal "𝕐"))

((generic_command) @mathbb_Z
  (#match? @mathbb_Z "\\\\mathbb\\{Z\\}")
  (#set! conceal "ℤ"))

; Mathcal fonts
((generic_command) @mathcal_symbol
  (#match? @mathcal_symbol "\\\\mathcal\\{([A-Z])\\}")
  (#set! conceal ""))

((generic_command) @mathcal_A
  (#match? @mathcal_A "\\\\mathcal\\{A\\}")
  (#set! conceal "𝒜"))

((generic_command) @mathcal_M
  (#match? @mathcal_M "\\\\mathcal\\{M\\}")
  (#set! conceal "ℳ"))

((generic_command) @mathcal_G
  (#match? @mathcal_G "\\\\mathcal\\{G\\}")
  (#set! conceal "𝒢"))

((generic_command) @mathcal_P
  (#match? @mathcal_P "\\\\mathcal\\{P\\}")
  (#set! conceal "𝒫"))

((generic_command) @mathcal_S
  (#match? @mathcal_S "\\\\mathcal\\{S\\}")
  (#set! conceal "𝒮"))

((generic_command) @mathcal_O
  (#match? @mathcal_O "\\\\mathcal\\{O\\}")
  (#set! conceal "𝒪"))

((generic_command) @mathcal_J
  (#match? @mathcal_J "\\\\mathcal\\{J\\}")
  (#set! conceal "𝒥"))

((generic_command) @mathcal_F
  (#match? @mathcal_F "\\\\mathcal\\{F\\}")
  (#set! conceal "ℱ"))

((generic_command) @mathcal_T
  (#match? @mathcal_T "\\\\mathcal\\{T\\}")
  (#set! conceal "𝒯"))

((generic_command) @mathcal_Y
  (#match? @mathcal_Y "\\\\mathcal\\{Y\\}")
  (#set! conceal "𝒴"))

((generic_command) @mathcal_D
  (#match? @mathcal_D "\\\\mathcal\\{D\\}")
  (#set! conceal "𝒟"))

((generic_command) @mathcal_L
  (#match? @mathcal_L "\\\\mathcal\\{L\\}")
  (#set! conceal "ℒ"))

((generic_command) @mathcal_Z
  (#match? @mathcal_Z "\\\\mathcal\\{Z\\}")
  (#set! conceal "𝒵"))

((generic_command) @mathcal_U
  (#match? @mathcal_U "\\\\mathcal\\{U\\}")
  (#set! conceal "𝒰"))

((generic_command) @mathcal_W
  (#match? @mathcal_W "\\\\mathcal\\{W\\}")
  (#set! conceal "𝒲"))

((generic_command) @mathcal_V
  (#match? @mathcal_V "\\\\mathcal\\{V\\}")
  (#set! conceal "𝒱"))

((generic_command) @mathcal_H
  (#match? @mathcal_H "\\\\mathcal\\{H\\}")
  (#set! conceal "ℋ"))

((generic_command) @mathcal_X
  (#match? @mathcal_X "\\\\mathcal\\{X\\}")
  (#set! conceal "𝒳"))

((generic_command) @mathcal_R
  (#match? @mathcal_R "\\\\mathcal\\{R\\}")
  (#set! conceal "ℛ"))

((generic_command) @mathcal_E
  (#match? @mathcal_E "\\\\mathcal\\{E\\}")
  (#set! conceal "ℰ"))

((generic_command) @mathcal_B
  (#match? @mathcal_B "\\\\mathcal\\{B\\}")
  (#set! conceal "ℬ"))

((generic_command) @mathcal_I
  (#match? @mathcal_I "\\\\mathcal\\{I\\}")
  (#set! conceal "ℐ"))

((generic_command) @mathcal_N
  (#match? @mathcal_N "\\\\mathcal\\{N\\}")
  (#set! conceal "𝒩"))

((generic_command) @mathcal_K
  (#match? @mathcal_K "\\\\mathcal\\{K\\}")
  (#set! conceal "𝒦"))

((generic_command) @mathcal_C
  (#match? @mathcal_C "\\\\mathcal\\{C\\}")
  (#set! conceal "𝒞"))

((generic_command) @mathcal_Q
  (#match? @mathcal_Q "\\\\mathcal\\{Q\\}")
  (#set! conceal "𝒬"))

((generic_command) @mathcal_H
  (#match? @mathcal_H "\\\\mathcal\\{H\\}")
  (#set! conceal "ℋ"))

((generic_command) @mathcal_T
  (#match? @mathcal_T "\\\\mathcal\\{T\\}")
  (#set! conceal "𝒯"))

((generic_command) @mathcal_X
  (#match? @mathcal_X "\\\\mathcal\\{X\\}")
  (#set! conceal "𝒳"))

((generic_command) @mathcal_Y
  (#match? @mathcal_Y "\\\\mathcal\\{Y\\}")
  (#set! conceal "𝒴"))

((generic_command) @mathcal_Z
  (#match? @mathcal_Z "\\\\mathcal\\{Z\\}")
  (#set! conceal "𝒵"))

; mathfrak fonts
((generic_command) @mathfrak_symbol
  (#match? @mathfrak_symbol "\\\\mathfrak\\{([A-Z])\\}")
  (#set! conceal ""))

((generic_command) @mathfrak_e
  (#match? @mathfrak_e "\\\\mathfrak\\{e\\}")
  (#set! conceal "𝔢"))

((generic_command) @mathfrak_k
  (#match? @mathfrak_k "\\\\mathfrak\\{k\\}")
  (#set! conceal "𝔨"))

((generic_command) @mathfrak_r
  (#match? @mathfrak_r "\\\\mathfrak\\{r\\}")
  (#set! conceal "𝔯"))

((generic_command) @mathfrak_T
  (#match? @mathfrak_T "\\\\mathfrak\\{T\\}")
  (#set! conceal "𝔗"))

((generic_command) @mathfrak_Y
  (#match? @mathfrak_Y "\\\\mathfrak\\{Y\\}")
  (#set! conceal "𝔜"))

((generic_command) @mathfrak_H
  (#match? @mathfrak_H "\\\\mathfrak\\{H\\}")
  (#set! conceal "ℌ"))

((generic_command) @mathfrak_E
  (#match? @mathfrak_E "\\\\mathfrak\\{E\\}")
  (#set! conceal "𝔈"))

((generic_command) @mathfrak_W
  (#match? @mathfrak_W "\\\\mathfrak\\{W\\}")
  (#set! conceal "𝔚"))

((generic_command) @mathfrak_I
  (#match? @mathfrak_I "\\\\mathfrak\\{I\\}")
  (#set! conceal "ℑ"))

((generic_command) @mathfrak_d
  (#match? @mathfrak_d "\\\\mathfrak\\{d\\}")
  (#set! conceal "𝔡"))

((generic_command) @mathfrak_l
  (#match? @mathfrak_l "\\\\mathfrak\\{l\\}")
  (#set! conceal "𝔩"))

((generic_command) @mathfrak_f
  (#match? @mathfrak_f "\\\\mathfrak\\{f\\}")
  (#set! conceal "𝔣"))

((generic_command) @mathfrak_m
  (#match? @mathfrak_m "\\\\mathfrak\\{m\\}")
  (#set! conceal "𝔪"))

((generic_command) @mathfrak_z
  (#match? @mathfrak_z "\\\\mathfrak\\{z\\}")
  (#set! conceal "𝔷"))

((generic_command) @mathfrak_y
  (#match? @mathfrak_y "\\\\mathfrak\\{y\\}")
  (#set! conceal "𝔶"))

((generic_command) @mathfrak_x
  (#match? @mathfrak_x "\\\\mathfrak\\{x\\}")
  (#set! conceal "𝔵"))

((generic_command) @mathfrak_O
  (#match? @mathfrak_O "\\\\mathfrak\\{O\\}")
  (#set! conceal "𝔒"))

((generic_command) @mathfrak_j
  (#match? @mathfrak_j "\\\\mathfrak\\{j\\}")
  (#set! conceal "𝔧"))

((generic_command) @mathfrak_n
  (#match? @mathfrak_n "\\\\mathfrak\\{n\\}")
  (#set! conceal "𝔫"))

((generic_command) @mathfrak_X
  (#match? @mathfrak_X "\\\\mathfrak\\{X\\}")
  (#set! conceal "𝔛"))

((generic_command) @mathfrak_B
  (#match? @mathfrak_B "\\\\mathfrak\\{B\\}")
  (#set! conceal "𝔅"))

((generic_command) @mathfrak_U
  (#match? @mathfrak_U "\\\\mathfrak\\{U\\}")
  (#set! conceal "𝔘"))

((generic_command) @mathfrak_C
  (#match? @mathfrak_C "\\\\mathfrak\\{C\\}")
  (#set! conceal "ℭ"))

((generic_command) @mathfrak_b
  (#match? @mathfrak_b "\\\\mathfrak\\{b\\}")
  (#set! conceal "𝔟"))

((generic_command) @mathfrak_c
  (#match? @mathfrak_c "\\\\mathfrak\\{c\\}")
  (#set! conceal "𝔠"))

((generic_command) @mathfrak_u
  (#match? @mathfrak_u "\\\\mathfrak\\{u\\}")
  (#set! conceal "𝔲"))

((generic_command) @mathfrak_t
  (#match? @mathfrak_t "\\\\mathfrak\\{t\\}")
  (#set! conceal "𝔱"))

((generic_command) @mathfrak_F
  (#match? @mathfrak_F "\\\\mathfrak\\{F\\}")
  (#set! conceal "𝔉"))

((generic_command) @mathfrak_h
  (#match? @mathfrak_h "\\\\mathfrak\\{h\\}")
  (#set! conceal "𝔥"))

((generic_command) @mathfrak_q
  (#match? @mathfrak_q "\\\\mathfrak\\{q\\}")
  (#set! conceal "𝔮"))

((generic_command) @mathfrak_p
  (#match? @mathfrak_p "\\\\mathfrak\\{p\\}")
  (#set! conceal "𝔭"))

((generic_command) @mathfrak_o
  (#match? @mathfrak_o "\\\\mathfrak\\{o\\}")
  (#set! conceal "𝔬"))

((generic_command) @mathfrak_P
  (#match? @mathfrak_P "\\\\mathfrak\\{P\\}")
  (#set! conceal "𝔓"))

((generic_command) @mathfrak_G
  (#match? @mathfrak_G "\\\\mathfrak\\{G\\}")
  (#set! conceal "𝔊"))

((generic_command) @mathfrak_R
  (#match? @mathfrak_R "\\\\mathfrak\\{R\\}")
  (#set! conceal "ℜ"))

((generic_command) @mathfrak_D
  (#match? @mathfrak_D "\\\\mathfrak\\{D\\}")
  (#set! conceal "𝔇"))

((generic_command) @mathfrak_L
  (#match? @mathfrak_L "\\\\mathfrak\\{L\\}")
  (#set! conceal "𝔏"))

((generic_command) @mathfrak_v
  (#match? @mathfrak_v "\\\\mathfrak\\{v\\}")
  (#set! conceal "𝔳"))

((generic_command) @mathfrak_w
  (#match? @mathfrak_w "\\\\mathfrak\\{w\\}")
  (#set! conceal "𝔴"))

((generic_command) @mathfrak_A
  (#match? @mathfrak_A "\\\\mathfrak\\{A\\}")
  (#set! conceal "𝔄"))

((generic_command) @mathfrak_i
  (#match? @mathfrak_i "\\\\mathfrak\\{i\\}")
  (#set! conceal "𝔦"))

((generic_command) @mathfrak_s
  (#match? @mathfrak_s "\\\\mathfrak\\{s\\}")
  (#set! conceal "𝔰"))

((generic_command) @mathfrak_g
  (#match? @mathfrak_g "\\\\mathfrak\\{g\\}")
  (#set! conceal "𝔤"))

((generic_command) @mathfrak_V
  (#match? @mathfrak_V "\\\\mathfrak\\{V\\}")
  (#set! conceal "𝔙"))

((generic_command) @mathfrak_a
  (#match? @mathfrak_a "\\\\mathfrak\\{a\\}")
  (#set! conceal "𝔞"))

((generic_command) @mathfrak_K
  (#match? @mathfrak_K "\\\\mathfrak\\{K\\}")
  (#set! conceal "𝔎"))

((generic_command) @mathfrak_M
  (#match? @mathfrak_M "\\\\mathfrak\\{M\\}")
  (#set! conceal "𝔐"))

((generic_command) @mathfrak_N
  (#match? @mathfrak_N "\\\\mathfrak\\{N\\}")
  (#set! conceal "𝔑"))

((generic_command) @mathfrak_S
  (#match? @mathfrak_S "\\\\mathfrak\\{S\\}")
  (#set! conceal "𝔖"))

((generic_command) @mathfrak_J
  (#match? @mathfrak_J "\\\\mathfrak\\{J\\}")
  (#set! conceal "𝔍"))

((generic_command) @mathfrak_Z
  (#match? @mathfrak_Z "\\\\mathfrak\\{Z\\}")
  (#set! conceal "ℨ"))

((generic_command) @mathfrak_Q
  (#match? @mathfrak_Q "\\\\mathfrak\\{Q\\}")
  (#set! conceal "𝔔"))

; Use early filtering for symbols - match only commands in math mode
((command_name) @_cmd
  (#any-of? @_cmd
    "\\alpha" "\\beta" "\\gamma" "\\delta" "\\epsilon" "\\zeta" "\\eta" "\\theta" "\\iota" "\\kappa"
    "\\lambda")
  (#has-ancestor? @_cmd math_environment)
  (#not-has-ancestor? @_cmd text_mode))

; Math subscripts and superscripts conceals
(text
  word: (subscript) @conceal
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal text_mode label_definition)
  (#any-of? @conceal
    "_0" "_1" "_2" "_3" "_4" "_5" "_6" "_7" "_8" "_9" "_a" "_e" "_h" "_i" "_j" "_k" "_l" "_m" "_n"
    "_o" "_p" "_r" "_s" "_t" "_u" "_v" "_x" "_\\."))

((subscript) @_sub
  (#eq? @_sub "_0")
  (#set! conceal "₀"))

((subscript) @_sub
  (#eq? @_sub "_1")
  (#set! conceal "₁"))

((subscript) @_sub
  (#eq? @_sub "_2")
  (#set! conceal "₂"))

((subscript) @_sub
  (#eq? @_sub "_3")
  (#set! conceal "₃"))

((subscript) @_sub
  (#eq? @_sub "_4")
  (#set! conceal "₄"))

((subscript) @_sub
  (#eq? @_sub "_5")
  (#set! conceal "₅"))

((subscript) @_sub
  (#eq? @_sub "_6")
  (#set! conceal "₆"))

((subscript) @_sub
  (#eq? @_sub "_7")
  (#set! conceal "₇"))

((subscript) @_sub
  (#eq? @_sub "_8")
  (#set! conceal "₈"))

((subscript) @_sub
  (#eq? @_sub "_9")
  (#set! conceal "₉"))

((subscript) @_sub
  (#eq? @_sub "_a")
  (#set! conceal "ₐ"))

((subscript) @_sub
  (#eq? @_sub "_e")
  (#set! conceal "ₑ"))

((subscript) @_sub
  (#eq? @_sub "_h")
  (#set! conceal "ₕ"))

((subscript) @_sub
  (#eq? @_sub "_i")
  (#set! conceal "ᵢ"))

((subscript) @_sub
  (#eq? @_sub "_j")
  (#set! conceal "ⱼ"))

((subscript) @_sub
  (#eq? @_sub "_k")
  (#set! conceal "ₖ"))

((subscript) @_sub
  (#eq? @_sub "_l")
  (#set! conceal "ₗ"))

((subscript) @_sub
  (#eq? @_sub "_m")
  (#set! conceal "ₘ"))

((subscript) @_sub
  (#eq? @_sub "_n")
  (#set! conceal "ₙ"))

((subscript) @_sub
  (#eq? @_sub "_o")
  (#set! conceal "ₒ"))

((subscript) @_sub
  (#eq? @_sub "_p")
  (#set! conceal "ₚ"))

((subscript) @_sub
  (#eq? @_sub "_r")
  (#set! conceal "ᵣ"))

((subscript) @_sub
  (#eq? @_sub "_s")
  (#set! conceal "ₛ"))

((subscript) @_sub
  (#eq? @_sub "_t")
  (#set! conceal "ₜ"))

((subscript) @_sub
  (#eq? @_sub "_u")
  (#set! conceal "ᵤ"))

((subscript) @_sub
  (#eq? @_sub "_v")
  (#set! conceal "ᵥ"))

((subscript) @_sub
  (#eq? @_sub "_x")
  (#set! conceal "ₓ"))

((subscript) @_sub
  (#eq? @_sub "_\\.")
  (#set! conceal "‸"))

(text
  word: (subscript) @conceal
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#any-of? @conceal "_+" "_-" "_/"))

((subscript) @_sub
  (#eq? @_sub "_+")
  (#set! conceal "₊"))

((subscript) @_sub
  (#eq? @_sub "_-")
  (#set! conceal "₋"))

((subscript) @_sub
  (#eq? @_sub "_/")
  (#set! conceal "ˏ"))

(text
  word: (superscript) @conceal
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#any-of? "^1" "^{1}"))

((superscript) @_sup
  (#eq? @_sup "^0")
  (#set! conceal "⁰"))

((superscript) @_sup
  (#eq? @_sup "^1")
  (#set! conceal "¹"))

((superscript) @_sup
  (#eq? @_sup "^{1}")
  (#set! conceal "¹"))

((superscript) @_sup
  (#eq? @_sup "^2")
  (#set! conceal "²"))

((superscript) @_sup
  (#eq? @_sup "^3")
  (#set! conceal "³"))

((superscript) @_sup
  (#eq? @_sup "^4")
  (#set! conceal "⁴"))

((superscript) @_sup
  (#eq? @_sup "^5")
  (#set! conceal "⁵"))

((superscript) @_sup
  (#eq? @_sup "^6")
  (#set! conceal "⁶"))

((superscript) @_sup
  (#eq? @_sup "^7")
  (#set! conceal "⁷"))

((superscript) @_sup
  (#eq? @_sup "^8")
  (#set! conceal "⁸"))

((superscript) @_sup
  (#eq? @_sup "^9")
  (#set! conceal "⁹"))

((superscript) @_sup
  (#eq? @_sup "^a")
  (#set! conceal "ᵃ"))

((superscript) @_sup
  (#eq? @_sup "^b")
  (#set! conceal "ᵇ"))

((superscript) @_sup
  (#eq? @_sup "^c")
  (#set! conceal "ᶜ"))

((superscript) @_sup
  (#eq? @_sup "^d")
  (#set! conceal "ᵈ"))

((superscript) @_sup
  (#eq? @_sup "^e")
  (#set! conceal "ᵉ"))

((superscript) @_sup
  (#eq? @_sup "^f")
  (#set! conceal "ᶠ"))

((superscript) @_sup
  (#eq? @_sup "^g")
  (#set! conceal "ᵍ"))

(text
  word: (superscript) @conceal
  (#any-of? @conceal "^+" "^-" "^<" "^>" "^/" "^=" "^\\.")
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal text_mode label_definition))

((superscript) @_sup
  (#eq? @_sup "^+")
  (#set! conceal "⁺"))

((superscript) @_sup
  (#eq? @_sup "^-")
  (#set! conceal "⁻"))

((superscript) @_sup
  (#eq? @_sup "^<")
  (#set! conceal "˂"))

((superscript) @_sup
  (#eq? @_sup "^>")
  (#set! conceal "˃"))

((superscript) @_sup
  (#eq? @_sup "^/")
  (#set! conceal "ˊ"))

((superscript) @_sup
  (#eq? @_sup "^\\.")
  (#set! conceal "˙"))

((superscript) @_sup
  (#eq? @_sup "^=")
  (#set! conceal "˭"))

; Greek letters
; First match all Greek letters in a single pattern
((command_name) @greek_letter
  (#any-of? @greek_letter
    "\\alpha" "\\beta" "\\gamma" "\\delta" "\\epsilon" "\\zeta" "\\eta" "\\theta" "\\iota" "\\kappa"
    "\\lambda" "\\mu" "\\nu" "\\xi" "\\pi" "\\rho" "\\sigma" "\\tau" "\\upsilon" "\\phi" "\\chi"
    "\\psi" "\\omega")
  (#has-ancestor? @greek_letter math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @greek_letter label_definition text_mode))

; Then define individual conceals
((command_name) @alpha
  (#eq? @alpha "\\alpha")
  (#set! conceal "α"))

((command_name) @beta
  (#eq? @beta "\\beta")
  (#set! conceal "β"))

((command_name) @gamma
  (#eq? @gamma "\\gamma")
  (#set! conceal "γ"))

((command_name) @delta
  (#eq? @delta "\\delta")
  (#set! conceal "δ"))

((command_name) @_cmd
  (#eq? @_cmd "\\zeta")
  (#set! conceal "ζ"))

((command_name) @_cmd
  (#eq? @_cmd "\\eta")
  (#set! conceal "η"))

((command_name) @_cmd
  (#eq? @_cmd "\\theta")
  (#set! conceal "θ"))

((command_name) @_cmd
  (#eq? @_cmd "\\iota")
  (#set! conceal "ι"))

((command_name) @_cmd
  (#eq? @_cmd "\\kappa")
  (#set! conceal "κ"))

((command_name) @_cmd
  (#eq? @_cmd "\\lambda")
  (#set! conceal "λ"))

((command_name) @_cmd
  (#eq? @_cmd "\\mu")
  (#set! conceal "μ"))

((command_name) @_cmd
  (#eq? @_cmd "\\nu")
  (#set! conceal "ν"))

((command_name) @_cmd
  (#eq? @_cmd "\\xi")
  (#set! conceal "ξ"))

((command_name) @_cmd
  (#eq? @_cmd "\\pi")
  (#set! conceal "π"))

((command_name) @_cmd
  (#eq? @_cmd "\\rho")
  (#set! conceal "ρ"))

((command_name) @_cmd
  (#eq? @_cmd "\\sigma")
  (#set! conceal "σ"))

((command_name) @_cmd
  (#eq? @_cmd "\\tau")
  (#set! conceal "τ"))

((command_name) @_cmd
  (#eq? @_cmd "\\upsilon")
  (#set! conceal "υ"))

((command_name) @_cmd
  (#eq? @_cmd "\\phi")
  (#set! conceal "φ"))

((command_name) @_cmd
  (#eq? @_cmd "\\chi")
  (#set! conceal "χ"))

((command_name) @_cmd
  (#eq? @_cmd "\\psi")
  (#set! conceal "ψ"))

((command_name) @_cmd
  (#eq? @_cmd "\\omega")
  (#set! conceal "ω"))

; Common symbols - individual definitions
((command_name) @math_symbol
  (#any-of? @math_symbol
    "\\infty" "\\sum" "\\prod" "\\int" "\\pm" "\\mp" "\\cap" "\\cup" "\\nabla" "\\partial" "\\times"
    "\\wedge" "\\langle" "\\rangle" "\\hbar" "  \\rightarrow" "\\leftarrow" "\\longrightarrow")
  (#has-ancestor? @math_symbol math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @math_symbol label_definition text_mode))

((command_name) @_cmd
  (#eq? @_cmd "\\rightarrow")
  (#set! conceal "->"))

((command_name) @_cmd
  (#eq? @_cmd "\\leftarrow")
  (#set! conceal "<-"))

((command_name) @_cmd
  (#eq? @_cmd "\\longrightarrow")
  (#set! conceal "-->"))

((command_name) @_cmd
  (#eq? @_cmd "\\langle")
  (#set! conceal "⟨"))

((command_name) @_cmd
  (#eq? @_cmd "\\rangle")
  (#set! conceal "⟩"))

((command_name) @_cmd
  (#eq? @_cmd "\\hbar")
  (#set! conceal "ℏ"))

((command_name) @_cmd
  (#eq? @_cmd "\\infty")
  (#set! conceal "∞")) ; ∞

((command_name) @_cmd
  (#eq? @_cmd "\\sum")
  (#set! conceal "∑")) ; ∑

((command_name) @_cmd
  (#eq? @_cmd "\\prod")
  (#set! conceal "∏")) ; ∏

((command_name) @_cmd
  (#eq? @_cmd "\\int")
  (#set! conceal "∫")) ; ∫

((command_name) @_cmd
  (#eq? @_cmd "\\pm")
  (#set! conceal "±")) ; ±

((command_name) @_cmd
  (#eq? @_cmd "\\mp")
  (#set! conceal "∓")) ; ∓

((command_name) @_cmd
  (#eq? @_cmd "\\cap")
  (#set! conceal "∩")) ; ∩

((command_name) @_cmd
  (#eq? @_cmd "\\cup")
  (#set! conceal "∪")) ; ∪

((command_name) @_cmd
  (#eq? @_cmd "\\nabla")
  (#set! conceal "∇")) ; ∇

((command_name) @_cmd
  (#eq? @_cmd "\\partial")
  (#set! conceal "∂")) ; ∂

((command_name) @_cmd
  (#eq? @_cmd "\\times")
  (#set! conceal "×")) ; ×

((command_name) @_cmd
  (#eq? @_cmd "\\wedge")
  (#set! conceal "∧"))

; Conceal the command part
((command_name) @_cmd
  (#any-of? @_cmd "\\displaystyle")
  (#set! conceal ""))
