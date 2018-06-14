

;-----------------------------------------------------;
;Keyboard                                             ;
;-----------------------------------------------------;

(define (emit-kbinit)
  (print ":kb_init")
  (print "  SET A, 0x0004")
  (print "  SET B, 0x0000")
  (print "  HWI I")
  (print "  SET A, 0x0003")
  (print "  SET B, 0x8000")
  (print "  BOR B, I")
  (print "  HWI I")
  (print "  SET PC, hwinit_loop_end")
)


(define (emit-kb-isr)
  (print ":kb_isr")
  (print "  SET C, A")
  (print "  AND C, 0x00FF")
  (print "  SET A, 0x0001")
  (print "  HWI C");get the character
  (print "  SET A, [stdin]") ;a = head offset
  (print "  SET B, stdin") ;b = base
  (print "  ADD B, 2") ;move b to head of data
  (print "  ADD B, A") ;increment b by offset
  (print "  SET [B], C") ;put the character into the proper memory address
  (print "  ADD A, 1") ;increment the offset
  (print "  MOD A, 10") ;loop around if the offset is greater than the size of the buffer
  (print "  SET [stdin], A") ;store the offset
  (print "  SET PC, isr_end") ;bail
)




;-----------------------------------------------------;
;Monitor                                              ;
;-----------------------------------------------------;


(define (emit-leminit)
  (print ":lem_init")
  (print "  SET A, 0")
  (print "  SET B, vram")
  (print "  HWI I")
  (print "  SET [vram], 0")
  (print "  SET PC, hwinit_loop_end"))


