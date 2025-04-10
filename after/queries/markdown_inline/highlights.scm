; ((latex_block) 
;   @conceal (#set! conceal_lines "") (#set! injection.language "latex"))
; ((latex_span_delimiter) 
;   @conceal (#set! conceal_lines "") (#set! injection.language "latex"))
; ((latex_span_delimiter) @_delimiter
;  (#set! conceal "")
;  (#set! injection.language "latex")
;  (#set! conceal_lines ""))
; ((inline
;   (latex_block) @latex)
;   (#set! conceal "")
;   (#set! conceal_lines "") (#set! injection.language "latex"))
;
; ;; Conceal LaTeX delimiter lines using conceal_lines feature
; (
;   (latex_block
;     (latex_span_delimiter) @latex.delimiter.start
;     (#set! conceal "")
;     (#set! conceal_lines ""))
; )
;
; (
;   (latex_block
;     .
;     (_)
;     (latex_span_delimiter) @latex.delimiter.end
;     (#set! conceal "")
;     (#set! conceal_lines ""))
; )
;
; ;; Make sure the content is properly handled as LaTeX
; ((latex_block) @latex.content (#set! injection.language "latex"))
