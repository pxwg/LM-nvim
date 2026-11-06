; extends
; Inline Org math is Typst in this config. \[...\] and $$...$$ (display_math_block)
; are LaTeX-only delimiters and keep orgmode's default handling.
; Property values are literal metadata: quoting and escaping belong to their
; schema, so their dollar strings must not enter the Typst renderer.
((inline_math_block) @injection.content
  (#not-has-ancestor? @injection.content "property_drawer")
  (#set! injection.language "typst")
  (#set! injection.include-children))
