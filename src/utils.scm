

(define unique-label
  (let ((count 0))
    (lambda ()
      (let ((L (string->symbol (format "l_~s" count))))
        (set! count (+ count 1))
        L))))

(define (unwind s i max)
  (if (eq? i max)
      (print "  ADD SP, " max)
      (begin (print s " [SP + " i "]")
      (unwind s (+ i 1) max))))

(define (unwind-intern s s2 i max)
  (if (eq? i max)
      (print "  ADD SP, " max)
      (begin (if (eq? i 0)
                  (print s " [SP]" s2)
                  (print s " [SP + " i "]"  s2))
             (unwind-intern s s2 (+ i 1) max))))

(define (emit-TF)
  (print "  ADD PC, 3")
  (print "  SET Z, 47")
  (print "  ADD PC, 2")
  (print "  SET Z, 111"))

(define (emit-and-save x si env)
  (if debug (print ";emit-and-save " x " si: " si " env: " env ))
  (if (eq? (cdr x) '() )
      (emit-expr (car x) si env)
      (begin 
       (emit-and-save (cdr x) si env)
       (print "  SET PUSH, Z")
       (emit-expr (car x) (- si 1) env))))

(define (emit-maskChk x) 
  (print "  IFE Z, " x)
  (emit-TF))


(define (contains list val)
  (if (null? (cdr list))
      (if (eq? (caar list) val) #t)
      (begin
        (if (eq? (caar list) val) #t (contains (cdr list) val)))))
