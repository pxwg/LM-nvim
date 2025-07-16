; extends

((math_environment
  (begin
    (curly_group_text
      (text) @_env)))
  (#any-of? @_env "equation" "equation*")
  (#set! conceal "")
  (#set! conceal_lines ""))

((math_environment
  (end
    (curly_group_text
      (text) @_env)))
  (#any-of? @_env "equation" "equation*")
  (#set! conceal "")
  (#set! conceal_lines ""))
