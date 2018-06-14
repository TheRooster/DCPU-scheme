(include "hardware.scm")

(define (emit-jump)
  (print "  SET PC, hwinit"))

(define (emit-vtable x)
  (print ""))

(define (emit-preamble)
  (print ":freeList\n.dat 0x0000")
  (if with-kb (print ":stdin\n.reserve 12")) ;head + tail + buffer space
  (if with-lem1802 (print ":vram\n.reserve 417")) ;cursor offset + 386 words vram + one blank scroll line
  (if with-kb (emit-getc))
  (if with-lem1802 (emit-putc))
  (emit-malloc)
  (emit-isr))

(define (emit-end)
  (print ":end")
  (print "  SUB PC, 1")
  (print ".org 0x7FFF")
  (print ":heap_begin")
  (emit-hwinit))

(define (emit-hwinit)
  (print ":hwinit")
  (print "  SET [freeList], heap_begin")
  (print "  HWN Z")
  (print "  SET I, 0")
  (print ":hwinit_loop")
  (print "  HWQ I")
  (if with-kb (print "  IFE A, 0x7406\n   IFE B, 0x30cf\n    SET PC, kb_init"))
  (if with-lem1802 (print "  IFE A, 0xf615\n   IFE B, 0x7349\n    SET PC, lem_init"))
  (print ":hwinit_loop_end")
  (print "  ADD I, 1")
  (print "  IFE I, Z")
  (print "   ADD PC, 2")
  (print "  SET PC, hwinit_loop")
  (print "  SET A, ISR")
  (print "  SET B, 0")
  (print "  IAS A")
  (print "  IAQ B")
  (print "  SET PC, main")
  (if with-kb (emit-kbinit))
  (if with-lem1802 (emit-leminit)))



(define (emit-isr)
  (print ":isr")
  (print "  SET PUSH, EX")
  (print "  SET PUSH, B")
  (print "  SET PUSH, C")
  (print "  SET PUSH, I")
  (print "  SET PUSH, J")
  (print "  SET PUSH, X")
  (print "  SET PUSH, Y")
  (print "  SET PUSH, Z")
  (print "  ;handle interrupt")
  (print "  SET B, A")
  (print "  AND B, 0xFF00") ;strip the number, leaving just the tag
  (if with-kb (print "  IFE B, 0x8000\n   SET PC, kb_isr"))
  (print ":isr_end")
  (print "  SET Z, POP")
  (print "  SET Y, POP")
  (print "  SET X, POP")
  (print "  SET J, POP")
  (print "  SET I, POP")
  (print "  SET C, POP")
  (print "  SET B, POP")
  (print "  SET EX, POP")
  (print "  RFI A")
  (if with-kb (emit-kb-isr))
  )




(define (emit-getc)
  (print ":getc")
  (print "  SET A, [stdin]") ; A holds the value of head
  (print "  SET B, [stdin + 1]") ; B holds the value of tail
  (print "  IFE A, B")
  (print "   SET PC, getc")
  (print "  ADD B, 2") ; offset + 2 to get over pointers
  (print "  SET Z, [stdin + B]") ; get the character
  (print "  SUB B, 1")
  (print "  SET [stdin+1], B") ;increment the pointer
)

(define (call-getc)
  (print "  JSR putc"))


(define (emit-putc)
  (print ":putc")
  (print ";  check for special chars here")
  (print "  SET A, [vram]")
  (print "  SET B, vram + 1")
  (print "  ADD A, B")
  (print "  BOR Z, 0xF000")
  (print "  SET [A], Z")
  (print "  ADD A, 1")
  (print "  SUB A, B")
  (print "  IFL A, 384")
  (print "  SET PC, putc_end")
  (print "  SET I, B")
  (print ":scroll")
  (print "  SET [I], [I+32]")
  (print "  ADD I, 1")
  (print "  SUB I, B")
  (print "  IFE I, 384")
  (print "   ADD PC, 2")
  (print "  ADD I, B")
  (print "  SET PC, scroll")
  (print "  SUB A, 32")
  (print ":putc_end")
  (print "  SET [VRAM], A")
  (print "  SET PC, POP"))


(define (call-putc)
  (print "  JSR putc"))


(define (emit-malloc) ;realllllly stupid malloc setup for now
  (print ":malloc")
  (print "  SET A, [freeList]")
  (print "  ADD A, Z")
  (print "  SET Z, [freeList]")
  (print "  SET [freeList], A")
  (print "  SET PC, POP"))

(define (call-malloc)
  (print "  JSR malloc"))


(define (emit-call x si env argc)
  (if debug (print ";emit-call " x))
  (print "  SET PUSH, Z")
  (if (eq? (car x) 'p)
      (print "  JSR " (cddr x))
      (print "  JSR [SP + " (+ (- (cddr x) si) 1) "]"))
  (print "  ADD SP, " argc))

(define (emit-if x si env)
  (let ((altrn (unique-label))
        (end (unique-label)))
   (emit-expr (car (cdr x)) si env)
   (if debug (print ";if"))
   (print "  IFN Z, 111")
   (print "  SET PC, " altrn)
   (emit-expr (car (cdr (cdr x))) si env)
   (print "  SET PC, "end)
   (print ":" altrn)
   (emit-expr (car (cdr (cdr (cdr x)))) si env)
   (print ":" end )))


;TODO: only call this if CONS was called in the program
(define (emit-load)
  (print ":load")
  (print "  SHR Z, 1")
  (print "  ADD Z, 32768")
  (print "  SET Y, [Z]")
  (print "  SET Z, [Z+1]")
  (print "  SET PC, POP"))

