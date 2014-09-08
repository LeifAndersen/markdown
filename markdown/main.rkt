#lang racket

(require "parse.rkt"
         "display-xexpr.rkt"
         "toc.rkt"
         feature-profile
         feature-profile/plug-in-lib
         (only-in profile/render-text render)
         (only-in profile/analyzer    analyze-samples)
         parsack)

(provide (all-from-out "parse.rkt")
         (all-from-out "display-xexpr.rkt")
         (all-from-out "toc.rkt"))

(define parsack-features
  (list
   (feature "Parsack Backtracking" 'feature-profile:parsack-backtracking
            values
            ;; From https://github.com/stamourv/marketplace
            ;; commit c3574966bc
            (λ (f-p)
              (define  intern (make-interner))
              (define post-processed
                (for/list ([c-s (feature-report-core-samples f-p)]
                           [p-s (cdr (feature-report-raw-samples f-p))])
                  (define processed
                    (let loop ([vs (filter values c-s)])
                      (if (null? vs) '(ground) (cons vs (loop (cdr vs))))))
                  (list* (car p-s) (cadr p-s) ; thread id and timestamp
                         (for/list ([v processed])
                           (intern (cons v #f))))))
              ;; Call edge profiler
              (newline) (newline) (displayln "Parsack Backtracking")
              (render (analyze-samples (cons (feature-report-total-time f-p) post-processed)))))))

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
