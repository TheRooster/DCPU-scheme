

(define (process-lambda-bindings x si env)
  (if debug (print ";process-lambda-bindings " x " env: " env))
  (if (eq? (cdr x) '())
      (bind-formal (car x) si env)
      (bind-formal (car x) (- si 1) (process-lambda-bindings (cdr x) si env))))

(define (bind-formal x si env)
  (if debug (print ";BIND-FORMAL " x " . " si))
  (cons (cons 'l (cons x (- si 1))) env))

(define (process-bindings x si env)
  (if (eq? (cdr x) '())
      (bind (car x) si env)
      (process-bindings (cdr x) (- si 1) (bind (car x) si env))))

(define (bind x si env)
  (if debug (print ";BIND "  x " . " si))
  (if (lambda? (cadr x))
      (let ((label (symbol->string (unique-label)))
            (endLabel (symbol->string (unique-label))) )
           (bind-local-lambda (cadr x) si (cons (cons 'p (cons (car x) label)) env) label endLabel))
      (begin
        (emit-and-save (cdr x) si env)
        (print "  SET PUSH, Z")
        (cons (cons 'l (cons (car x) (- si 1))) env))
  ))

(define (bind-local-lambda x si env label endLabel )
  (if standalone (print "  SET PC, "endLabel)(print "  ADD PC, " endLabel " - pre_"endLabel "\n:pre_"endLabel))
  (emit-lambda x si env label)
  (print ":" endLabel )
  env)

(define (emit-var x si env)
  (if debug (print ";emit-var " x " si: " si))
  (if (eq? (car x) 'l)
      (if (eq? (cddr x) si) (print "  SET Z, [SP]")(print "  SET Z, [SP+"  (- (cddr x) si)"]"))
      (if standalone (print "  SET Z, " (cddr x))(print "  SET A, PC\n:var"(cddr x)"\n  SUB A, var"(cddr x)" - "(cddr x) "\n  SET Z, A"))))

(define (lookup var si env)
  (if debug (print ";lookup " var " env: " env))
  (if (eq? env '())
      (print "ERROR: " var " not bound in env")
      (if (eq? (cadr (car env)) var)
          (car env)
          (lookup var si (cdr env)))))

(define (emit-let x si env)
  (if debug (print ";LET"))
  (emit-expr (caddr x) (- si (length (cadr x))) (process-bindings (cadr x) si env))
  (let ((argc (count-let-args (cadr x))))
       (if (not (eq? argc 0))
           (print "  ADD SP, " argc))) ;reset the stack
  (if debug (print ";END LET")))


(define (count-let-args x)
  (if debug (print "count-let-args " x))
  (if (null? x)
      0
      (if (lambda? (cadar x))
        (count-let-args (cdr x))
        (+ 1 (count-let-args (cdr x))))))


(define (emit-lambda x si env label)
  (if debug (print ";LAMBDA"))
  (print ":" label)
  (emit-expr (caddr x) (- si (+ (length (cadr x)) 1)) (process-lambda-bindings (cadr x) si env))
  (print "  SET PC, POP") env)


(define (process-define x si env)
  (if debug (print ";define " x " env: " env))
  (if (lambda? (caddr x))
      (let ((label (symbol->string (unique-label))))
           (emit-lambda (caddr x) si (cons (cons 'p (cons (cadr x) label)) env) label ))
      (cons (cons 'g (cdr x)) env)))

