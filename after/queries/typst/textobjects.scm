; extends

; Label references (@xxxx)
(ref) @reference.outer

((math
  "$"
  (_) @_start
  (_)? @_end
  "$") @math.outer)

((math
  "$"
  ([_] @math.inner)*
  "$"))

; Section textobject. Keep this query directive-free because mini.ai evaluates the
; whole textobjects query without nvim-treesitter-textobjects' custom directives.
((section
  (heading
    "=" @head_operator)
  .
  (_)
  (_)? .) @section.outer)
