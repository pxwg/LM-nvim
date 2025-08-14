; extends

((math_environment
  (begin
    (curly_group_text
      (text) @_env))@_line)
  (#any-of? @_env "equation" "equation*")
  (#set! @_line conceal ""))

((math_environment
  (end
    (curly_group_text
      (text) @_env))@_line)
  (#any-of? @_env "equation" "equation*")
  (#set! @_line conceal ""))
