; extends

((math
  "$"
  (_) @_start
  (_)? @_end
  "$") @math.outer)

((math
  "$"
  ([_] @math.inner)* 
  "$"))

; extends

; General section with form ==... xxx
; ((section
;   ((heading) @head_operator
;     (#match? @head_operator "^=\\s+.*"))
;   .
;   (_) @start
;   (_)? @end .) @section.outer
;   (#make-range! "section.inner" @start @end))

((section
  (heading 
    "=" @head_operator)
  .
  (_) @start
  (_)? @end .) @section.outer
  (#make-range! "section.inner" @start @end))

; ((section((heading) @head_operator
;          (#match? @head_operator "^=\\s+.*"))
;          .
;          (_)
;          (_)?
;          .
;   ) @section.outer)
