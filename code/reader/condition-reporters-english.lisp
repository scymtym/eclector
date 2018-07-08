(cl:in-package #:eclector.reader)

(macrolet
    ((define-reporter (((condition-var condition-specializer) stream-var)
                       &body body)
       `(defmethod acclimation:report-condition
            ((,condition-var ,condition-specializer)
             ,stream-var
             (language acclimation:english))
          ,@body)))

  (define-reporter ((condition end-of-file) stream)
    (format stream "Unexpected end of file."))

  (define-reporter ((condition invalid-context-for-backquote) stream)
    (format stream "Backquote has been used in a context that does not ~
                    permit it (like #C(1 `,2))."))

  (define-reporter ((condition comma-not-inside-backquote) stream)
    (format stream "~:[Comma~;Splicing comma~] not inside backquote."
            (at-sign-p condition)))

  (define-reporter ((condition object-must-follow-comma) stream)
    (format stream "An object must follow a~:[~; splicing~] comma."
            (at-sign-p condition)))

  (define-reporter ((condition unquote-splicing-in-dotted-list) stream)
    (format stream "Splicing unquote at end of list (like a . ,@b)."))

  (define-reporter ((condition unquote-splicing-at-top) stream)
    (format stream "Splicing unquote as backquote form (like `,@foo)."))

  (define-reporter ((condition invalid-context-for-consing-dot) stream)
    (format stream "A consing dot appeared in an illegal position."))

  (define-reporter ((condition object-must-follow-consing-dot) stream)
    (format stream "An object must follow a consing dot."))

  (define-reporter ((condition multiple-objects-following-consing-dot) stream)
    (format stream "Only a single object can follow a consing dot."))

  (define-reporter ((condition invalid-context-for-right-parenthesis) stream)
    (format stream "Unmatched close parenthesis."))

  (define-reporter ((condition package-does-not-exist) stream)
    (format stream "Package named ~s does not exist."
            (desired-package-name condition)))

  (define-reporter ((condition symbol-does-not-exist) stream)
    (format stream "Symbol named ~s not found in the ~a package."
            (desired-symbol-name condition)
            (package-name (desired-symbol-package condition))))

  (define-reporter ((condition symbol-is-not-external) stream)
    (format stream "Symbol named ~s is not external in the ~a package."
            (desired-symbol-name condition)
            (package-name (desired-symbol-package condition))))

  (define-reporter ((condition symbol-name-must-not-end-with-package-marker) stream)
    (format stream "Symbol name must not end with a package ~
                    marker (the : character)."))

  (define-reporter ((condition two-package-markers-must-be-adjacent) stream)
    (format stream "If a symbol token contains two package markers, ~
                    they must be adjacent as in package::symbol."))

  (define-reporter ((condition two-package-markers-must-not-be-first) stream)
    (format stream "A symbol token must not start with two package ~
                    markers as in ::name."))

  (define-reporter ((condition symbol-can-have-at-most-two-package-markers) stream)
    (format stream "A symbol token must not contain more than two ~
                    package markers as in package:::symbol or ~
                    package::first:rest."))

  (define-reporter ((condition uninterned-symbol-must-not-contain-package-marker) stream)
    (format stream "A symbol token following #: must not contain a ~
                    package marker."))

  (define-reporter ((condition numeric-parameter-supplied-but-ignored) stream)
    (format stream "Dispatch reader macro ~a was supplied with a ~
                    numeric parameter it does not accept."
            (macro-name condition)))

  (define-reporter ((condition numeric-parameter-not-supplied-but-required) stream)
    (format stream "Dispatch reader macro ~a requires a numeric ~
                    parameter, but none was supplied."
            (macro-name condition)))

  (define-reporter ((condition read-time-evaluation-inhibited) stream)
    (format stream "Cannot evaluate expression at read-time because ~s ~
                    is false."
            '*read-eval*))

  (define-reporter ((condition read-time-evaluation-error) stream)
      (let ((expression (expression condition))
            (original-condition (original-condition condition)))
        (format stream "Read-time evaluation of expression ~s signaled ~
                        ~s: ~a"
                expression (type-of original-condition) original-condition)))

  (define-reporter ((condition unknown-character-name) stream)
    (format stream "Unrecognized character name: ~s" (name condition)))

  (define-reporter ((condition digit-expected) stream)
    (format stream "~:c is not a digit in base ~d."
            (character-found condition) (base condition)))

  (define-reporter ((condition invalid-radix) stream)
    (format stream "~d is too ~:[big~;small~] to be a radix."
            (radix condition) (< (radix condition) 2)))

  (define-reporter ((condition invalid-default-float-format) stream)
    (format stream "~a is not a valid ~a."
            (float-format condition) 'cl:*read-default-float-format*))

  (define-reporter ((condition too-many-elements) stream)
    (format stream "~a was specified to have length ~d, but ~d ~
                    element~:P ~:*~[were~;was~:;were~] found."
            (array-type condition)
            (expected-number condition)
            (number-found condition)))

  (define-reporter ((condition no-elements-found) stream)
    (format stream "~a was specified to have length ~d, but no ~
                    elements were found."
            (array-type condition) (expected-number condition)))

  (define-reporter ((condition incorrect-initialization-length) stream)
    (format stream "~a was specified to have length ~d along the ~:R ~
                    axis, but provided initial-contents don't ~
                    match:~%~a"
            (array-type condition)
            (expected-length condition)
            (1+ (axis condition))
            (datum condition)))

  (define-reporter ((condition single-feature-expected) stream)
    (format stream "Bad feature expression- found multiple features ~
                    when only one was expected:~%~a"
            (features condition)))

  (define-reporter ((condition sharpsign-invalid) stream)
    (format stream "~:c is not a valid subchar for the # dispatch macro."
            (character-found condition)))

  (define-reporter ((condition sharpsign-equals-label-defined-more-than-once) stream)
    (format stream "Sharpsign reader macro label ~d defined more than once."
            (label condition)))

  (define-reporter ((condition sharpsign-sharpsign-undefined-label) stream)
    (format stream "Reference to undefined label #~d#." (label condition)))

  ) ; MACROLET DEFINE-REPORTER
