(include "defines.scm")
(include "utils.scm")
(include "primitives.scm")
(if standalone (include "standalone.scm")(include "linkable.scm"))


(define (emit-prim x si env)
    (if debug (print "\n  ;" (car x)))
    (if (not (null? (cdr x))) (emit-and-save (cdr x) si env))
    (cond
      ((eq? (car x) '++ )    (print "  ADD Z, " (imrep 1)))
      ((eq? (car x) '-- )    (print "  SUB Z, " (imrep 1)))
      ((eq? (car x) 'atoi)   (print "  SHR Z, 8")
                             (print "  SHL Z, 1"))
      ((eq? (car x) 'itoa)   (print "  SHL Z, 7")
                             (print "  ADD Z, 255"))
      ((eq? (car x) 'fxnum?) (print "  IFC Z, 1")
                             (print "  ADD PC, 3")
                             (print "  SET Z, 47")
                             (print "  ADD PC, 2")
                             (print "  SET Z, 111"))
      ((eq? (car x) 'bool?)  (print "  AND Z, 15")
                             (emit-maskChk 15))
      ((eq? (car x) 'null?)  (print "  AND Z, 255")
                             (emit-maskChk 63))
      ((eq? (car x) 'char?)  (print "  AND Z, 255")
                             (emit-maskChk 255))
      ((eq? (car x) 'not)    (print "  XOR Z, 64"))
      ((eq? (car x) 'pair?)  (print "  AND Z, 3")
                             (print "  IFE Z, 1")
                             (print "  ADD PC, 3")
                             (print "  SET Z, 47")
                             (print "  ADD PC, 2")
                             (print "  SET Z, 111"))
      ((eq? (car x) 'zero?)  (print "  IFE Z, 0")
                             (print "  ADD PC, 3")
                             (print "  SET Z, 47")
                             (print "  ADD PC, 2")
                             (print "  SET Z, 111"))
      ((eq? (car x) 'car)    (print "  JSR load")
                             (print "  SET Z, Y"))
      ((eq? (car x) 'cdr)    (print "  JSR load"))
      
      ((eq? (car x) 'cons)   (print "  SET PUSH, Z")
                             (print "  SET Z, 2")
      			     (call-malloc)
      			     (print "  SET [Z], [SP]")
                             (print "  SET [Z+1], [SP + 1]"))
      
      ((eq? (car x) 'putc)   (call-putc)) 
      ((eq? (car x) 'getc)   (call-getc)) 
      ;n-ary instructions    
      ((eq? (car x) '+)      (unwind "  ADD Z, " 0 (- (length (cdr x)) 1)) )
      ((eq? (car x) '-)      (unwind "  SUB Z, " 0 (- (length (cdr x)) 1)))
      ((eq? (car x) '<<)     (unwind-intern "  SET A," "\n  SHR A, 1\n  SHL Z, A" 0 (- (length (cdr x)) 1)))
      ((eq? (car x) '>>)     (unwind-intern "  SET A," "\n  SHR A, 1\n  SHR Z, A" 0 (- (length (cdr x)) 1)))
      ((eq? (car x) '*)      (unwind "  MUL Z, " 0 (- (length (cdr x)) 1)))
      ((eq? (car x) '/)      (unwind "  DIV Z, " 0 (- (length (cdr x)) 1)))
      ((eq? (car x) '%)      (print "  MOD Z, [SP] \n  ADD SP, 1"))
      ((eq? (car x) '&)      (unwind "  AND Z, " 0 (- (length (cdr x)) 1)))

      ((eq? (car x) '||)      (unwind "  BOR Z, " 0 (- (length (cdr x)) 1)))
      ((eq? (car x) '^)      (unwind "  XOR Z, " 0 (- (length (cdr x)) 1)))
      ((eq? (car x) '==)     (print "  IFE Z, [SP]")
                             (print "  ADD PC, 3")
                             (print "  SET Z, 47")
                             (print "  ADD PC, 2")
                             (print "  SET Z, 111"))
      ((eq? (car x) '<)       (unwind-intern "  IFL Z," "\n  ADD PC, 3\n  SET Z, 47\n  ADD PC, 2\n  SET Z, 111" 0 (- (length (cdr x)) 1)))  
      ((eq? (car x) '>)       (unwind-intern "  IFG Z," "\n  ADD PC, 3\n  SET Z, 47\n  ADD PC, 2\n  SET Z, 111" 0 (- (length (cdr x)) 1)))  
      
      
      ((lambda? (car x))     (emit-expr (car x) si env))
      (else                  (emit-call (lookup (car x) si env) si env (length (cdr x)))) ;user defined procedure or local variable
    ) env) 


  
(define (emit-expr x si env)
  (if debug (print ";emit-expr " x " si: " si " env: " env))
  (cond
    ((imm? x) (emit-imm x si env))
    ((if? x) (emit-if x si env))
    ((let? x)(emit-let x si env))
    ((symbol? x) (emit-var (lookup x si env) si env));emit-var
    ((lambda? x) (emit-lambda x si env (symbol->string (unique-label))))
    ((define? x) (process-define x si env))
    ((begin? x) (emit-begin (cdr x) si env))
    (else (emit-prim x si env))))

(define (emit-multiexpr x si env)
  (if debug (print ";emit-multi " x " env: " env))
  (if (eq? (cdr x) '())
      (begin
      (print ":main")
      (emit-expr (car x) si env))
      (cons (emit-multiexpr (cdr x) si (emit-expr (car x) si env)) env)))


(define (compile x)
 (emit-jump)
 (let ((env (emit-vtable x)))
 ;Set up for future runtime error handling
 ;(print ":panic")
 ;(print "  SET Z, 0xBEEF")
 ;(print "  ;LOG Z")
 ;(if standalone (print "  SET PC, end") (print "  ADD PC, end - preend\n:preend"))
 (emit-load)
 (emit-preamble)
 (emit-multiexpr  x 100 env))
 (emit-end))

