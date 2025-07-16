;; extends
((math
  "$"
  .
  (_) @_start
  (_)? @_end
  .
  "$") @math.outer
  (#make-range! "math.inner" @_start @_end))
