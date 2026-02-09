;https://gist.github.com/life00/e60d4feb1e23510a56c4d0991033dc1d
; ; extends
;
; ; set! is used to conceal the node with a single character string
; ; offset! is used to offset the concealed selection in the node
; ; horizontal rule
; ((thematic_break) @markup.link.label.markdown_inline
;   (#set! conceal "―"))
;
; ; level 1 bullet
; (list
;   (list_item
;     [
;       (list_marker_minus)
;       (list_marker_plus)
;       (list_marker_star)
;     ] @markup.link.label.markdown_inline
;     (#set! conceal "●")
;     (#offset! @markup.link.label.markdown_inline 0 0 0 -1)))
;
; ; level 2 bullet
; (list
;   (list_item
;     (list
;       (list_item
;         [
;           (list_marker_minus)
;           (list_marker_plus)
;           (list_marker_star)
;         ] @markup.link.label.markdown_inline
;         (#set! conceal "◉")
;         (#offset! @markup.link.label.markdown_inline 0 0 0 -1)))))
;
; ; level 3 bullet
; (list
;   (list_item
;     (list
;       (list_item
;         (list
;           (list_item
;             [
;               (list_marker_minus)
;               (list_marker_plus)
;               (list_marker_star)
;             ] @markup.link.label.markdown_inline
;             (#set! conceal "○")
;             (#offset! @markup.link.label.markdown_inline 0 0 0 -1)))))))
;
; ; level 4 and above bullet
; (list
;   (list_item
;     (list
;       (list_item
;         (list
;           (list_item
;             (list
;               (list_item
;                 [
;                   (list_marker_minus)
;                   (list_marker_plus)
;                   (list_marker_star)
;                 ] @markup.link.label.markdown_inline
;                 (#set! conceal "•")
;                 (#offset! @markup.link.label.markdown_inline 0 0 0 -1)))))))))
;
; ; '●', '○', '◆', '◇'; '◉'; '•'
; ; global bullet for minus
; ; ((list_marker_minus) @punctuation.special.list_minus.conceal (#set! conceal "•") (#offset! @punctuation.special.list_minus.conceal 0 0 0 -1))
; ; conceal checkboxes
; ((task_list_marker_unchecked) @text.todo.unchecked
;   (#offset! @text.todo.unchecked 0 -2 0 0)
;   (#set! conceal "✗"))
;
; ((task_list_marker_checked) @text.todo.checked
;   (#offset! @text.todo.checked 0 -2 0 0)
;   (#set! conceal "✓"))
;
; ; code block
; (fenced_code_block (fenced_code_block_delimiter) @conceal (#set! conceal ""))
; (fenced_code_block (info_string (language) @conceal (#set! conceal "")))
; ; block quotes
; (block_quote [(block_quote_marker)] @conceal (#set! conceal "▋") (#offset! @conceal 0 0 0 -1))
; (block_quote (block_quote_marker) (paragraph (inline (block_continuation) @conceal (#set! conceal "▋") (#offset! @conceal 0 0 0 -1))))
;
; ; horizontal rule
; ((thematic_break) @markup.link.label.markdown_inline (#set! conceal "―"))
;
