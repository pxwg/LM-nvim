; extends

; 捕获整个代码块（包含反引号）作为 outer
(fenced_code_block) @fenced_code_block.outer

; 捕获代码块内部的内容作为 inner
; 注意：这里我们明确指定只捕获 fenced_code_block 内部的 code_fence_content
(fenced_code_block
  (code_fence_content) @fenced_code_block.inner)
