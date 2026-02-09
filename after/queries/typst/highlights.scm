(string
  "\"" @typ_inline_quote
  (#set! @typ_inline_quote conceal ""))

(call
  item: (ident) @typ_math_delim
  (#any-of? @typ_math_delim "lr" "left" "right")
  (#has-ancestor? @typ_math_delim math formula)
  (#set! conceal ""))
