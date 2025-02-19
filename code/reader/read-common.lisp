(cl:in-package #:eclector.reader)

;;; We have to provide our own PEEK-CHAR function because CL:PEEK-CHAR
;;; obviously does not use Eclector's readtable.

(defun peek-char (&optional peek-type
                            (input-stream *standard-input*)
                            (eof-error-p t)
                            eof-value
                            recursive-p)
  (flet ((done (value)
           (cond ((not (eq value input-stream))
                  value)
                 (eof-error-p
                  (%reader-error input-stream 'end-of-file))
                 (t
                  eof-value))))
    (if (not (eq peek-type t))
        (done (cl:peek-char peek-type input-stream nil input-stream recursive-p))
        (loop with readtable = (state-value *client* 'cl:*readtable*)
              for char = (cl:peek-char nil input-stream nil input-stream recursive-p)
              while (and (not (eq char input-stream))
                         (eq (eclector.readtable:syntax-type readtable char)
                             :whitespace))
              do (read-char input-stream) ; consume whitespace char
              finally (return (done char))))))

;;; Establishing context

(defmethod call-as-top-level-read (client thunk input-stream
                                   eof-error-p eof-value preserve-whitespace-p)
  (declare (ignore eof-error-p eof-value))
  (multiple-value-prog1
      (call-with-label-tracking client thunk)
    ;; All reading in READ-COMMON and its callees was done in a
    ;; whitespace-preserving way. So we skip zero to one whitespace
    ;; characters here if requested via PRESERVE-WHITESPACE-P.
    (unless preserve-whitespace-p
      (let ((readtable (state-value client 'cl:*readtable*)))
        (skip-whitespace input-stream readtable)))))

(defmethod read-common (client input-stream eof-error-p eof-value)
  (loop for (value what . rest) = (multiple-value-list
                                   (read-maybe-nothing
                                    client input-stream eof-error-p eof-value))
        do (ecase what
             ((:eof :suppress :object)
              (return (apply #'values value rest)))
             ((:whitespace :skip)))))

(defun %read-maybe-nothing (client input-stream eof-error-p eof-value)
  (let ((char (read-char input-stream eof-error-p)))
    (when (null char)
      (return-from %read-maybe-nothing (values eof-value :eof)))
    (let ((readtable (state-value client 'cl:*readtable*)))
      (case (eclector.readtable:syntax-type readtable char)
        (:whitespace
         (skip-whitespace* input-stream readtable)
         (values nil :whitespace))
        ((:terminating-macro :non-terminating-macro)
         ;; There is no need to consider the value of EOF-ERROR-P in
         ;; reader macros since: "read signals an error of type
         ;; end-of-file, regardless of eof-error-p, if the file ends
         ;; in the middle of an object representation."  (HyperSpec
         ;; entry for READ)
         (let* ((*skip-reason* nil)
                (values (multiple-value-list
                         (call-reader-macro
                          client input-stream char readtable))))
           (cond ((null values)
                  (note-skipped-input client input-stream
                                      (or *skip-reason* :reader-macro))
                  (values nil :skip))
                 ;; This case takes care of reader macro not returning
                 ;; nil when *READ-SUPPRESS* is true.
                 ((state-value client '*read-suppress*)
                  (note-skipped-input client input-stream
                                      (or *skip-reason* '*read-suppress*))
                  (values nil :suppress))
                 (t
                  (values (first values) :object)))))
        (t
         (unread-char char input-stream)
         (let* ((*skip-reason* nil)
                (object (read-token client input-stream eof-error-p eof-value)))
           (cond ((and (eq object *consing-dot*)
                       (not *consing-dot-allowed-p*))
                  (%recoverable-reader-error
                   input-stream 'invalid-context-for-consing-dot
                   :position-offset -1 :report 'skip-token)
                  (values nil :skip))
                 (t
                  (values object (if (state-value client '*read-suppress*)
                                     :suppress
                                     :object))))))))))

(defmethod read-maybe-nothing (client input-stream eof-error-p eof-value)
  (%read-maybe-nothing client input-stream eof-error-p eof-value))
