;; extends
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

;; extends
; Conceal the command part
((command_name) @_cmd
 (#any-of? @_cmd "\\displaystyle") 
 (#set! conceal ""))

; ; Conceal the opening brace
; ((generic_command
;   command: (command_name) @_cmd
;   arg: (curly_group "{" @_open_brace))
;  (#any-of? @_cmd "\\mathrm" "\\mathit" "\\textit" "\\mathbf" "\\textbf" "\\emph")
;  (#set! @_open_brace conceal ""))
;
; ; Conceal the closing brace
; ((generic_command
;   command: (command_name) @_cmd
;   arg: (curly_group "}" @_close_brace))
;  (#any-of? @_cmd "\\mathrm" "\\mathit" "\\textit" "\\mathbf" "\\textbf" "\\emph")
;  (#set! @_close_brace conceal ""))
;
