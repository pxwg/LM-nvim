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
;
; ; Conceal the command part
; ((command_name) @_cmd
;  (#any-of? @_cmd "\\mathrm" "\\mathit" "\\textit" "\\mathbf" "\\textbf" "\\emph" ) 
;  (#set! conceal ""))
;
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
; ((command_name) @math_symbol
;  (#any-of? @math_symbol 
;     "\\infty" "\\sum" "\\prod" "\\int" "\\pm" "\\mp" "\\cap" "\\cup" "\\nabla" "\\partial" "\\times" "\\wedge" "\\langle" "\\rangle" "\\hbar" "  \\rightarrow" "\\leftarrow"  "\\longrightarrow" "\\{" "\\}")
;  (#has-ancestor? @math_symbol math_environment inline_formula displayed_equation)
;  (#not-has-ancestor? @math_symbol label_definition text_mode))
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\rightarrow")
;   (#set! conceal "->"))
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\leftarrow")
;   (#set! conceal "<-"))
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\longrightarrow")
;   (#set! conceal "-->"))
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\langle")
;   (#set! conceal "⟨"))
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\rangle")
;   (#set! conceal "⟩"))
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\hbar")
;   (#set! conceal "ℏ"))
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\infty")
;   (#set! conceal "∞"))  ; ∞
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\sum")
;   (#set! conceal "∑"))  ; ∑
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\prod")
;   (#set! conceal "∏"))  ; ∏
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\int")
;   (#set! conceal "∫"))  ; ∫
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\pm")
;   (#set! conceal "±"))  ; ±
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\mp")
;   (#set! conceal "∓"))  ; ∓
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\cap")
;   (#set! conceal "∩"))  ; ∩
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\cup")
;   (#set! conceal "∪"))  ; ∪
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\nabla")
;   (#set! conceal "∇"))  ; ∇
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\partial")
;   (#set! conceal "∂"))  ; ∂
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\times")
;   (#set! conceal "×"))  ; ×
;
; ((command_name) @_cmd
;   (#eq? @_cmd "\\wedge")
;   (#set! conceal "∧"))
;
; ; Conceal the command part
; ((command_name) @_cmd
;  (#any-of? @_cmd "\\displaystyle") 
;  (#set! conceal ""))
;
; ; Conceal the command part
; ((command_name) @_cmd
;  (#any-of? @_cmd "\\{") 
;  (#set! conceal "{"))
;
; ((command_name) @_cmd
;  (#any-of? @_cmd "\\}") 
;  (#set! conceal "}"))
