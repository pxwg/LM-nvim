; extends

; Keep upstream structural folds (including modern #let zk-metadata declarations).
; Also support legacy metadata comment blocks without replacing upstream queries.
((comment) @fold
  (#match? @fold "^/\\* Metadata:"))
