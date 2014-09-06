#lang racket

(require "parse.rkt"
         "display-xexpr.rkt"
         "toc.rkt"
         feature-profile
         feature-profile/plug-in-lib
         parsack)

(provide (all-from-out "parse.rkt")
         (all-from-out "display-xexpr.rkt")
         (all-from-out "toc.rkt"))

(define parsack-features
  (list
   (feature "Parsack Backtracking" 'feature-profile:parsack-backtracking (λ (x) x) #f)))

(define parsack-syntactic-latent-mark-keys
  (append (map feature-key parsack-features) default-syntactic-latent-mark-keys))

(define (build-function-latent-marks in data)
  (match data
    ['() in]

    [`((,mark) . ,rest) (build-function-latent-marks in rest)]
    [`((,mark ,function . ,function*) . ,rest)
     (dict-set* (build-function-latent-marks in `((,mark . ,function*) . ,rest))
                function mark)]
   [else (error "Invalid data: ~a" data)]))

(define parsack-functional-latent-marks
  (build-function-latent-marks default-functional-latent-marks
                               (list (list 'feature-profile:parsack
                                           #'<or>2))))

(define parsack-profile-compile-handler
  (make-latent-mark-compile-handler parsack-syntactic-latent-mark-keys
                                    parsack-functional-latent-marks))

;(current-compile parsack-profile-compile-handler)

;; For use as command-line pipe.
(module+ main
  (feature-profile
   #:extra-features parsack-features
   (begin
     (display "<!DOCTYPE html>")
     (display-xexpr `(html (head () (meta ([charset "utf-8"])))
                           (body () ,@(read-markdown)))))))
