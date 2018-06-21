
(define (emit-jump)
  (print " ADD PC, main-vtab"))

;TODO: Define the initial environment and set up vtable for lining
(define (emit-vtable x)
  (print ":vtab")
  (print ":getc\n.DAT 0x0")
  (print ":putc\n.DAT 0x0")
  (print ":malloc\n.DAT 0x0")
  (print ":free\n.DAT 0x0"))

(define (print-list x)
  (if (null? (cdr x))
      (print (car x))
      (begin 
	(print (car x))
	(print-list (cdr x)))))

(define (emit-preamble)
  (print ""))

(define (emit-end)
  (print ":end")
  (print "  SET PC, POP"))

(define (emit-calc-offset ident)
  (let ((lbl (symbol->string (unique-label))))
    (print "  SET A, PC")
    (print ":"ident"_"lbl)
    (print "  SUB A, "ident"_"lbl" - "ident)))

(define (call-getc)
  (emit-calc-offset "getc")
  (print "  JSR [A]"))

(define (call-putc)
  (emit-calc-offset "putc")
  (print "  JSR [A]"))

(define (call-malloc)
  (emit-calc-offset "malloc")
  (print "  JSR [A]"))

(define (emit-call x si env argc)
  (if debug (print ";emit-call " x))
  (print "  SET PUSH, Z")
  (if (eq? (car x) 'p)
      (begin 
	(print "  SET A, PC")
	(print ":call"(cddr x))
	(print "  SUB A, call"(cddr x)" - "(cddr x))
	(print "  JSR A"))
      (print "  ADD SP, " argc)))


(define (emit-if x si env)
  (let ((altrn (unique-label))
        (end (unique-label)))
   (emit-expr (car (cdr x)) si env)
   (if debug (print ";if"))
   (print "  IFN Z, 111")
   (print "  ADD PC, " altrn " - pre_"altrn)
   (print ":pre_"altrn)
   (emit-expr (car (cdr (cdr x))) si env)
   (print "  ADD PC, " end " - pre_"end)
   (print ":pre_"end )
   (print ":" altrn)
   (emit-expr (car (cdr (cdr (cdr x)))) si env)
   (print ":" end )))

(define (emit-load) ; need to revisit this, somehow need to tag pairs
  (print ":load")
  (print "  SET Y, [Z]")
  (print "  SET Z, [Z+1]")
  (print "  SET PC, POP"))
