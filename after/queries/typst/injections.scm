; extends

((call
  item: (ident) @func_name
  (group
    (raw_span
       (blob) @injection.content)))
 (#any-of? @func_name "mitex" "mitext")
 (#set! injection.language "latex")
 (#set! injection.include-children))

((call
  item: (ident) @func_name
  (group
    (raw_span
       (blob) @injection.content)))
 (#eq? @func_name "math-render")
 (#set! injection.language "markdown")
 (#set! injection.combined))
