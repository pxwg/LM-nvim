; extends

((command_name) @cmd
(#eq? @cmd "\\ali")
arg: (curly_group
       "{" @left_paren
       (_)
       "}" @right_paren)
(#set! @cmd conceal "")
(#set! @left_paren conceal "")
(#set! @right_paren conceal ""))

((command_name) @cmd
(#eq? @cmd "\\lR")
arg: (curly_group
       "{"
       (_)
       "}"  @punctuation.delimiter)
(#set! @cmd conceal "")
(#set! @punctuation.delimiter conceal "⟩"))

((command_name) @cmd
(#eq? @cmd "\\lR")
arg: (curly_group
       "{" @punctuation.delimiter
       (_)
       "}")
(#set! @cmd conceal "")
(#set! @punctuation.delimiter conceal "⟨"))

; ((math_environment
;   (begin
;     (curly_group_text
;       (text) @_env))@_line)
;   (#any-of? @_env "equation" "equation*")
;   (#set! @_line conceal ""))
;
; ((math_environment
;   (end
;     (curly_group_text
;       (text) @_env))@_line)
;   (#any-of? @_env "equation" "equation*")
;   (#set! @_line conceal ""))
