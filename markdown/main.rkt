#lang racket

(require "parse.rkt"
         "display-xexpr.rkt"
         "toc.rkt"
         feature-profile)

(provide (all-from-out "parse.rkt")
         (all-from-out "display-xexpr.rkt")
         (all-from-out "toc.rkt"))

;; For use as command-line pipe.
(module+ main
  (feature-profile
   #:extra-features parsack-features
   (begin
     (display "<!DOCTYPE html>")
     (display-xexpr `(html (head () (meta ([charset "utf-8"])))
                           (body () ,@(read-markdown)))))))
