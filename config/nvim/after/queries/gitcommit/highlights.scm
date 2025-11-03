; extends

; Higlight lines not following the 50/72 rule.
;
; See https://github.com/gbprod/tree-sitter-gitcommit/pull/68

((subject) @comment.error
  (#vim-match? @comment.error ".\{50,}")
  (#offset! @comment.error 0 50 0 0))

((message_line) @comment.error
  (#vim-match? @comment.error ".\{72,}")
  (#offset! @comment.error 0 72 0 0))
