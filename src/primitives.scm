
(define (fxnum? x)
  (and (integer? x) ( <= -16384 x 16383)))

(define (imm? x)
  (or (fxnum? x) (boolean? x) (char? x) (null? x)))

(define (imrep x)
  (cond
  ((fxnum? x) (* x 2))
  ((boolean? x) (if x 111 47))
  ((char? x) (+ (* (char->integer x) 256) 255))
  ((null? x) 63)
  (else (print "unable to create immediate representation"))))

(define (if? x)
  (and (pair? x) (eq? (car x) 'if)))

(define (let? x)
  (and (pair? x) (eq? (car x) 'let)))

(define (var? x)
  (symbol? x))

(define (lambda? x)
  (and (pair? x) (eq? (car x) '/.)))

(define (define? x)
  (and (pair? x) (eq? (car x) 'def)))

(define (begin? x)
  (and (pair? x) (eq? (car x) 'begin)))

(define (emit-imm x si env)  
  (if debug (print "  ;" x))
  (print "  SET Z, " (imrep x)))


(define (emit-begin x si env)
  (if debug (print ";emit-begin " x " env: " env))
  (if (eq? (cdr x) '())
      (emit-expr (car x) si env)
      (cons (emit-begin (cdr x) si (emit-expr (car x) si env)) env)))

