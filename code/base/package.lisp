(cl:defpackage #:eclector.base
  (:use
   #:common-lisp)

  (:shadow
   . #1=(#:end-of-file

         #:read-char))

  (:export
   . #1#)

  ;; Conditions (with accessors)
  (:export
   #:stream-position-reader-error
   #:stream-position

   #:end-of-file)

  ;; Exported for eclector.reader, not public use.
  (:export
   #:%reader-error))
