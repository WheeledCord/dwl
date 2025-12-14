;;; implicit ref/set -- tmisc.scm and tread.scm also have some

(set! (*s7* 'heap-size) 1024000)
(load "s7test-block.so" (sublet (curlet) (cons 'init_func 'block_init)))

(define size 50000)

(define (s1 obj val)
  (set! (obj 'a) val))

(define (s11 obj val)
  (set! ((obj 'b) 'a) val))

(define (s111 obj val)
  (set! (obj 'b 'a) val))

(define (s1111 obj sym val)
  (set! (obj 'b sym) val))

(define (s11111 obj sym val)
  (set! (obj 'b (car sym)) val))


(define (s2 obj val)
  (set! (obj 'a) (+ (log 4 2) val)))

(define (s22 obj val)
  (set! ((obj 'b) 'a) (+ (log 4 2) val)))

(define (s222 obj val)
  (set! (obj 'b 'a) (+ (log 4 2) val)))

(define (s2222 obj sym val)
  (set! (obj 'b sym) (+ (log 4 2) val)))

(define (s22222 obj sym val)
  (set! (obj 'b (car sym)) (+ (log 4 2) val)))


(define (s3 obj val)
  (set! (obj 'b :a) val))


(define (s4 obj val)
  (set! (obj 'b 1) val))

(define (s44 obj val)
  (set! (obj 'b (- (log 4 2) 1)) val))

(define (s444 obj val)
  (set! (obj 'b 1) (car val)))

(define (s4444 obj ind val)
  (set! (obj 'b ind) val))


(define (s5 obj val)
  (set! (obj 0 1) val))

(define (s55 obj val)
  (set! (obj 0 (- (log 4 2) 1)) val))

(define (s555 obj val)
  (set! (obj 0 1) (car val)))

(define (s5555 obj ind val)
  (set! (obj 0 ind) val))


(define (s6 obj val)
  (set! (((obj 'b) 'b) 'a) val))

(define (s66 obj val)
  (set! (((obj 'b) 'b) 'a) val))

(define (s666 obj val)
  (set! (obj 'b 'b 'a) val))

(define (s6666 obj val)
  (set! ((obj 'b) 'b 'a) val))


(define (s7 obj val)
  (set! (list-ref (obj 0) 0) val))

(define (s77 obj i1 i2 val)
  (set! (list-ref (obj i1) i2) val))

(define (s777 obj val)
  (set! ((obj 0)) 32))


(define (s8 obj val)
  (set! (obj 0) val))

(define (s88 obj ind val)
  (set! (obj ind) val))

(define (s888 obj ind val)
  (set! (obj ind) (integer->char val)))

(define (s8888 obj ind val)
  (set! (obj (+ ind 1)) (integer->char val)))

(define (stest)
  (let ((table (hash-table 'a 1 'b (hash-table 'a 3)))
	(table1 (hash-table 'b "12345"))
	(table2 (vector (vector 1 2 3)))
	(table3 (hash-table 'b (block 1 2 3)))
	;; (table4 (hash-table 'b (let ((x (vector 1 2 3))) (dilambda (lambda (ind) (x ind)) (lambda (ind val) (set! (x ind) val))))))
	(table5 (hash-table 'a 1 'b (hash-table 'a 3 'b (hash-table 'a 4))))
	(table6 (vector (list 0 1) (list 2 3)))
	(envir (inlet 'a 1 'b (inlet 'a 4)))
	(lst (list 0 1))
	(lst1 (list dilambda_test)) ; from s7test-block
	(lst2 (list (list 0 1)))
	(str "0123456789")
	(one 1))

    (do ((i 0 (+ i 1)))
	((= i size))

      (s1 table 12)
      (unless (= (table 'a) 12) (format *stderr* "[1]"))
      (s11 table 12)
      (unless (= ((table 'b) 'a) 12) (format *stderr* "[2]"))
      (s111 table 12)
      (unless (= (table 'b 'a) 12) (format *stderr* "[3]"))
      (s1111 table 'a 12)
      (unless (= (table 'b 'a) 12) (format *stderr* "[4]"))
      (s11111 table '(a) 12)
      (unless (= (table 'b 'a) 12) (format *stderr* "[5]"))

      (s1 envir 12)
      (s11 envir 12)
      (s111 envir 12)
      (s1111 envir 'a 12)
      (s11111 envir '(a) 12)

      (s2 table 12)
      (unless (= (table 'a) 14) (format *stderr* "[6]"))
      (s22 table 12)
      (unless (= ((table 'b) 'a) 14) (format *stderr* "[7]"))
      (s222 table 12)
      (unless (= (table 'b 'a) 14) (format *stderr* "[8]"))
      (s2222 table 'a 12)
      (unless (= (table 'b 'a) 14) (format *stderr* "[9]"))
      (s22222 table '(a) 12)
      (unless (= (table 'b 'a) 14) (format *stderr* "[10]"))

      (s2 envir 12)
      (s22 envir 12)
      (s222 envir 12)
      (s2222 envir 'a 12)
      (s22222 envir '(a) 12)

      (s3 envir 32)
      (unless (= (envir 'b 'a) 32) (format *stderr* "[11]"))

      (s4 table1 #\a) ; set_implicit_string
      (unless (char=? (table1 'b 1) #\a) (format *stderr* "[12]"))
      (s44 table1 #\a)
      (unless (char=? (table1 'b 1) #\a) (format *stderr* "[13]"))
      (s444 table1 '(#\a))
      (unless (char=? (table1 'b 1) #\a) (format *stderr* "[14]"))
      (s4444 table1 1 #\a)
      (unless (char=? (table1 'b 1) #\a) (format *stderr* "[15]"))

      (s4 table3 23.0) ; set_implicit_c_object
      (unless (= (table3 'b 1) 23.0) (format *stderr* "[16]"))
      (s44 table3 23.0)
      (unless (= (table3 'b 1) 23.0) (format *stderr* "[17]"))
      (s444 table3 '(23.0))
      (unless (= (table3 'b 1) 23.0) (format *stderr* "[18]"))
      (s4444 table3 1 23.0)
      (unless (= (table3 'b 1) 23.0) (format *stderr* "[19]"))

;      (s4 table4 23.0) ; set_implicit_closure -- now an error
;      (unless (= (table4 'b 1) 23.0) (format *stderr* "[20]"))
;      (s44 table4 23.0)
;      (unless (= (table4 'b 1) 23.0) (format *stderr* "[21]"))
;      (s444 table4 '(23.0))
;      (unless (= (table4 'b 1) 23.0) (format *stderr* "[22]"))
;      (s4444 table4 1 23.0)
;      (unless (= (table4 'b 1) 23.0) (format *stderr* "[23]"))

      (s5 table2 #\a) ; set_implicit_vector
      (unless (char=? (table2 0 1) #\a) (format *stderr* "[24]"))
      (s55 table2 #\a)
      (unless (char=? (table2 0 1) #\a) (format *stderr* "[25]"))
      (s555 table2 '(#\a))
      (unless (char=? (table2 0 1) #\a) (format *stderr* "[26]"))
      (s5555 table2 1 #\a)
      (unless (char=? (table2 0 1) #\a) (format *stderr* "[27]"))

      (s6 table5 12)
      (unless (= (((table5 'b) 'b) 'a) 12) (format *stderr* "[28]"))
      (s66 table5 12)
      (unless (= ((table5 'b) 'b 'a) 12) (format *stderr* "[29]"))
      (s666 table5 12)
      (unless (= (table5 'b 'b 'a) 12) (format *stderr* "[30]"))
      (s6666 table5 12)
      (unless (= (table5 'b 'b 'a) 12) (format *stderr* "[31]"))

      (s7 table6 12)
      (unless (= (table6 0 0) 12) (format *stderr* "[32]"))
      (s77 table6 0 1 12)
      (unless (= (table6 0 1) 12) (format *stderr* "[33]"))
      (s777 lst1 12)

      (s5 lst2 32)
      (unless (= (cadar lst2) 32) (format *stderr* "[34]"))
      (s55 lst2 12)
      (unless (= (cadar lst2) 12) (format *stderr* "[35]"))
      (s555 lst2 '(15))
      (unless (= (cadar lst2) 15) (format *stderr* "[36]"))
      (s5555 lst2 1 3)
      (unless (= (cadar lst2) 3) (format *stderr* "[37]"))

      (s8 str #\a)
      (unless (char=? (str 0) #\a) (format *stderr* "[38]"))
      (s88 str 1 #\b)
      (unless (char=? (str one) #\b) (format *stderr* "[39]"))
      (s888 str 2 (char->integer #\c))
      (unless (char=? (str (+ one 1)) #\c) (format *stderr* "[40]"))
      (s8888 str 2 (char->integer #\d))
      (unless (char=? (str 3) #\d) (format *stderr* "[41]"))
      (unless (string=? str "abcd456789") (format *stderr* "[42]"))

      )))

(stest)


(define len 1000000)

(define H (hash-table 'abs *))
(define (fabsH x)
  ((H 'abs) x 0.0001))

(define (f6) ; [719] -> [515 if func_one_arg handles hash] -> [508]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fabsH i))))))

;(f6)


(define P (list + * -))
(define (fabsP x)
  ((P 1) x 0.0001))

(define (f8) ; [700] -> [524 fx_implicit]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fabsP i))))))

;(f8)


(define V (vector + * -))
(define (fabsV x)
  ((V 1) x 0.0001))

(define (f9) ; [685] -> [512 fx_implicit]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fabsV i))))))

;(f9)


(define C (make-cycle *))
(define (fabsC x)
  ((C) x 0.0001))

(define (f10) ; [681] (there is no op_implicit_c_object_ref)
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fabsC i))))))

;(f10)


;;; implicit arg cases (also included elsewhere)
(define B (block .001 .0001 .00001)) ; C-object as arg
(define (fabsB x)
  (* x (B 1)))

(define (f11) ; [591] no fx_*_ref?? block_ref_p_pp -> [519] fx_implicit_c_object_ref_a -- why not opt?
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fabsB i))))))

;(f11)


(define P2 (list (list + * -) (list .001 .0001 .00001)))
(define (fabsP2 x)
  ((P2 0 1) x 0.0001))

(define (f12) ; [797]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fabsP2 i))))))

;(f12)


(define V2 #2d((#_+ #_* #_-) (.001 .0001 .00001)))
(define (fabsV2 x)
  ((V2 0 1) x 0.0001))

(define (f13) ; [778]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fabsV2 i))))))

;(f13)


(define (f14) ; [492]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (* i (P2 1 1)))))))

;(f14)


(define (f15) ; [185] -- [738] if (vector (vector ...))
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (* i (V2 1 1)))))))

;(f15)


(define H2 (hash-table 'a .0001))
(define (f16) ; [169] -- this is fully optimized!? -> [160] p_pp_sf_href!
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (* i (H2 'a)))))))

;(f16)


(define L2 (inlet 'a .0001))
(define (f17) ; [173] (no lref) -> [167] lref -> [131 slot_ref]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (* i (L2 'a)))))))

;(f17)


(define V3 (vector .0001))
(define (f18) ; [148] (opt_p_pi_sc(t_vector_ref_p_pi_unchecked))
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (* i (V3 0)))))))

;(f18)


(define P3 (list .0001))
(define (f19) ; [157] opt_p_pi_sc(list_ref_p_pi_unchecked)
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (* i (P3 0)))))))

;(f19)


(define B3 (block .0001))
(define (f20) ; [114] d_7pi_sf(block_ref_d_7pi)
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (* i (B3 0)))))))

;(f20)


(define V4 #2d((.0001)))
(define (f21) ; [185] opt_p_pii_sff(vector_ref_p_pii_direct)
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (* i (V4 0 0)))))))

;(f21)


;;; let cases
(define L (inlet 'abs *))
(define L_abs (L 'abs))

(define (fabs x)
  ((L 'abs) x 0.0001))
  ;((if (integer? x) * /) x 0.0001))

(define (fLabs x)
  (L_abs x 0.0001))

(define (frefabs x)
  ((let-ref L 'abs) x 0.0001))


(define (f1) ; [729] -> [507 fx_implicit_let_ref_c]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fabs i))))))

;(f1)


(define (f2) ; [298]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fLabs i))))))

;(f2)


(define (f3) ; [510]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (frefabs i))))))

;(f3)


(define f4 ; [559]
  (let ((L (openlet (inlet '+ (lambda (arg obj)
				(#_+ arg (obj 'value)))
			   'value 3))))
    (lambda ()
      (do ((i 0 (+ i 1)))
	  ((= i len) (+ 1 L 2))
	(unless (= (+ 1 L 2) 6) ; g_add_3 -> add_p_ppp -> 2 add_p_pp with a method call
	  (display "f4 oops\n"))))))

;(f4)


(define (fabsL x)
  ((L 'abs) x 0.0001))

(define (f5) ; [512, 723 if set L to H in the loop, 693 if int *??] -> [503?]
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fabsL i))))))

;(f5)


(define (fabs:L x)
  ((L :abs) x 0.0001))

(define (f22) ; [721] -> [504] (added keyword check)
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (fabs:L i))))))

;(f22)


(define size 1000000)

(define (f23) ; [134] opt'd
  (let ((sum 0.0)
	(L (inlet 'multiply  *)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum ((let-ref L 'multiply) i 0.0001))))))

;(display "f23 ") (display (f23)) (newline)


(define (f24) ; [605] -> [134 opt'd]
  (let ((sum 0.0)
	(L (inlet 'multiply  *)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum ((L 'multiply) i 0.0001))))))

;(display "f24 ") (display (f24)) (newline)


; check if (L 'multiply) is changed opt process is not used (fx):

(define (f24a) ; [690]
  (let ((sum 0.0)
	(L (inlet 'multiply  *))
	(H (hash-table 'multiply +)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum ((L 'multiply) i 0.0001)))
      (set! L H)))) ; apparently this blocks the optimizer -> op_x_aa etc

;(display "f24a ") (display (f24a)) (newline)


(define (f24b) ; [577]
  (let ((sum 0.0)
	(L (inlet 'multiply  *))
	(L1 (inlet 'multiply  +)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum ((L 'multiply) i 0.0001)))
      (set! L L1)))) ; same as above

;(display "f24b ") (display (f24b)) (newline)


(define (setL L)
  (set! (L 'multiply) floor))

(define (f24c-1) ; floor: too many arguments
  (let ((sum 0.0)
	(L (inlet 'multiply  *)))
    (do ((i 0 (+ i 1)))
	((= i 3) sum)
      (set! sum (+ sum ((L 'multiply) i 0.0001)))
      (setL L))))

(define (f24c) (catch #t f24c-1 (lambda args 'error)))
;(display "f24c ") (display (catch #t f24c-1 (lambda args 'error))) (newline)


(define (f24d-1) ; same error as above
  (let ((sum 0.0)
	(L (inlet 'multiply  *)))
    (do ((i 0 (+ i 1)))
	((= i 3) sum)
      (set! sum (+ sum ((L 'multiply) i 0.0001)))
      (let-set! L 'multiply floor))))

(define (f24d) (catch #t f24d-1 (lambda args 'error)))
;(display "f24d ") (display (catch #t f24d-1 (lambda args 'error))) (newline)


(define (f25) ; [638]
  (let ((sum 0.0)
	(L (inlet 'multiply  *)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum ((L 'multiply) i 0.0001)))
      (let-set! L 'multiply +))))

;(display "f25 ") (display (f25)) (newline)

#|
224,053,076  s7.c:eval.isra.0 [/home/bil/motif-snd/repl]  fx_c_scs = 125, op_x_aa = 188
 74,000,000  s7.c:fx_c_scs [/home/bil/motif-snd/repl]     let_set 60
 59,000,225  s7.c:add_p_pp [/home/bil/motif-snd/repl]
 47,999,952  s7.c:fx_implicit_let_ref_c [/home/bil/motif-snd/repl]
 46,999,953  s7.c:op_x_aa [/home/bil/motif-snd/repl]      implicit_let_ref aa="i 0.0001"
 27,000,000  s7.c:let_set_1 [/home/bil/motif-snd/repl]
 24,950,959  s7.c:g_add_x1 [/home/bil/motif-snd/repl]
 21,606,113  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 21,000,687  /usr/include/x86_64-linux-gnu/bits/string_fortified.h:eval.isra.0
 19,999,980  s7.c:g_add [/home/bil/motif-snd/repl]
 16,000,016  s7.c:g_num_eq_2 [/home/bil/motif-snd/repl]
 13,000,000  s7.c:let_ref_p_pp [/home/bil/motif-snd/repl]
|#


(require libm.scm)

(define (f26) ; if s7 sqrt via *libc* (! sqrt_p_p) [195] sqrt=30 gc=30, via *libm*: [246] sqrt=43 (s7__sqrt)+21 overhead, gc=30
  (let ((sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum ((*libm* 'sqrt) i))))))

;(display "f26 ") (display (f26)) (newline)


(define (f27) ; [268]
  (let ((sum 0.0)
	(L3 (inlet 'x 1.0)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum (L3 'x)))
      (set! (L3 'x) (* (L3 'x) 0.9999)))))

;(display "f27 ") (display (f27)) (newline)   ; 9999.999999994685

;;; (- 3.701520785793392e-44 (expt 0.9999 1000000)) 4.978412222288913e-59

#|
38,942,875  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
30,000,000  s7.c:opt_p_pp_sf_lref [/home/bil/motif-snd/repl]
29,000,000  s7.c:opt_p_ppp_sff [/home/bil/motif-snd/repl]
28,000,144  s7.c:add_p_pp [/home/bil/motif-snd/repl]
26,000,160  s7.c:multiply_p_pp [/home/bil/motif-snd/repl]
26,000,000  s7.c:let_set_1 [/home/bil/motif-snd/repl]            this could be simpler (key check, rootlet/unlet, slot search (save), slot setter in checked_slot_set)
21,689,904  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
18,000,044  s7.c:let_ref_p_pp [/home/bil/motif-snd/repl]
17,000,000  s7.c:opt_p_pp_fc [/home/bil/motif-snd/repl]
11,000,000  s7.c:opt_p_pp_sf_add [/home/bil/motif-snd/repl]
 9,000,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]              'x in the let-refs, opt_p_pp_sf_lref [build this in], save slot for let-ref too
 9,000,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]

to:

38,942,785  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
28,000,000  s7.c:add_p_pp [/home/bil/motif-snd/repl]
26,000,470  s7.c:multiply_p_pp [/home/bil/motif-snd/repl]
21,601,157  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
17,000,000  s7.c:opt_p_pp_fc [/home/bil/motif-snd/repl]
15,000,000  s7.c:opt_p_ppf_slot_set [/home/bil/motif-snd/repl]
11,000,000  s7.c:opt_p_pp_sf_add [/home/bil/motif-snd/repl]
 9,000,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
 8,000,000  s7.c:opt_p_pp_slot_ref [/home/bil/motif-snd/repl]
|#

(define (f28) ; [86 via opt_p_pp_sc_slot_ref]
  (let ((sum 0.0)
	(L3 (inlet 'x 1.0)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum (let-ref L3 'x))))))

;(display "f28 ") (display (f28)) (newline)


(define (f29) ; [267 unopt'd except for fx*]
  (let ((sum 0.0)
	(L5 (inlet 'x 0.1))
	(L3 (inlet 'x 1.0)))
    (do ((i 0 (+ i 1))
	 (L4 L3 L5))
	((= i size) sum)
      (set! sum (+ sum (let-ref L4 'x))))))

;(display "f29 ") (display (f29)) (newline)


(define (f30) ; [642 eval/inlet_p_pp, gc etc, let_set_1 and let_ref]
  (let ((sum 0.0)
	(L3 (inlet 'x 1.0)))
    (do ((i 0 (+ i 1))
	 (L4 L3 (inlet 'x 0.1)))
	((= i size) sum)
      (set! (L4 'x) (* 2.0 (L4 'x))) ; make sure it's a new inlet on each iteration
      (set! sum (+ sum (let-ref L4 'x))))))

;(display "f30 ") (display (f30)) (newline)


(define (f31) ; [105 opt_p_pp_ss_lref let_ref_p_pp] -> [86 opt_p_pp_sc_slot_ref]
  (let ((sum 0.0)
	(L3 (inlet 'x 1.0)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum (let-ref L3 :x))))))

;(display "f31 ") (display (f31)) (newline)


(define (f32) ; [109 opt_p_pp_sf_lref let_ref_p_pp and opt_p_c for 'x (I assume)] -> [86 slot_ref]
  (let ((sum 0.0)
	(L3 (inlet 'x 1.0)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum (L3 'x))))))

;(display "f32 ") (display (f32)) (newline)


(define (f32a) ; [105] -> [86 slot_ref]
  (let ((sum 0.0)
	(L3 (inlet 'x 1.0)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum (L3 :x))))))

;(display "f32a ") (display (f32a)) (newline)


(define (f33) ; [410, 552 if varlet on every iteration, fx_implicit_let_ref_c]
  (let ((sum 0.0)
	(L3 (inlet 'x 1.0)))
    (do ((i 0 (+ i 1)))
	((= i size) sum)
      (set! sum (+ sum (L3 'x)))
      (when (= i 0) (varlet L3 'x 0.5)))))

;(display "f33 ") (display (f33)) (newline)


(define (f34) ; [123 let_set_1 from let_set] 64755 (let-set! L3 :x (+ (L3 'x) 1)) -> [82] slot_set and slot_ref
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (let-set! L3 :x (+ (L3 'x) 1)))))

;(display "f34 ") (display (f34)) (newline)

#|
29,000,026  s7.c:let_set_1 [/home/bil/motif-snd/repl]
24,950,959  s7.c:g_add_xi [/home/bil/motif-snd/repl]
19,000,000  s7.c:opt_p_ppp_ssf [/home/bil/motif-snd/repl]            let_set 64750 p_ppp_ok
17,000,000  s7.c:opt_p_pi_fc [/home/bil/motif-snd/repl]
 8,000,008  s7.c:let_set [/home/bil/motif-snd/repl]
 7,000,094  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
 6,924,479  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 4,000,000  s7.c:opt_p_pp_sc_slot_ref [/home/bil/motif-snd/repl]     let-refs
 3,000,000  s7.c:add_p_pi [/home/bil/motif-snd/repl]

  to:

24,950,959  s7.c:g_add_xi [/home/bil/motif-snd/repl]
17,000,000  s7.c:opt_p_pi_fc [/home/bil/motif-snd/repl]
15,000,000  s7.c:opt_p_ppf_slot_set [/home/bil/motif-snd/repl]
 7,000,094  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
 6,924,494  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 4,000,000  s7.c:opt_p_pp_slot_ref [/home/bil/motif-snd/repl]
 3,000,000  s7.c:add_p_pi [/home/bil/motif-snd/repl]
|#


(define (f34a) ; [133] opt_p_ppp_sff -> let_set(_1) 64800 (let-set! L3 'x (+ (L3 'x) 1)) -> [82] as above
  (let ((L3 (inlet 'x 1.0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (let-set! L3 'x (+ (L3 'x) 1)))))

;(display "f34a ") (display (f34a)) (newline)


(define (f35) ; [141] -> [98]
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (set! (L3 'x) (+ (L3 'x) 1)))))

;(display "f35 ") (display (f35)) (newline)


(define (f35a) ; [33] opt_p_pps_slot_set
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (set! (L3 :x) i))))

;(display "f35a ") (display (f35a)) (newline)


(define (f35b) ; [66] -> [32] opt_p_ppc_slot_set -- twice as slow as f35i due to make_integer in opt_dotimes (set! is op_safe_do, let-set! is op_safe_dotimes in check_do)
               ;      -> [14] if sequence allows op_safe_dotimes (set! (L :x) val) as opposed to (let-set! L :x val)
               ;         but set! lacks has_fn and op_simple_do (the fallback) expects has_fn, so we lose
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (set! (L3 :x) 0))))

;(display "f35b ") (display (f35b)) (newline)


(define (f35c) ; [98] opt_p_ppf_slot_set and opt_p_pp_slot_ref
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (set! (L3 :x) (+ (L3 'x) 1)))))

;(display "f35c ") (display (f35c)) (newline)


(define (f35d) ; [61] 65890 -> [33] opt_p_pps_slot_set
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (set! (L3 'x) i))))

;(display "f35d ") (display (f35d)) (newline)


(define (f35e) ; [45] ppf_slot_set -> [32] opt_p_ppc_slot_set
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (set! (L3 'x) 0))))

;(display "f35e ") (display (f35e)) (newline) ; 0


(define (f35f) ; [63] -> [35] opt_p_pps_slot_set
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (let-set! L3 'x i))))

;(display "f35f ") (display (f35f)) (newline) ; 999999


(define (f35g) ; [29] opt_p_ppf_slot_set + opt_p_c -> [16] opt_p_ppc_slot_set
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (let-set! L3 'x 0))))

;(display "f35g ") (display (f35g)) (newline) ; 0


(define (f35h) ; [72] 64738 -> [35] opt_p_pps_slot_set
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (let-set! L3 :x i))))

;(display "f35h ") (display (f35h)) (newline) ; 999999


(define (f35i) ; [58] opt_p_ppp_ssc + let_set_1 -> [16] opt_ppc_slot_set
  (let ((L3 (inlet 'x 0)))
    (do ((i 0 (+ i 1)))
	((= i size) (L3 :x))
      (let-set! L3 :x 0))))

;(display "f35i ") (display (f35i)) (newline)


(define (test-all)
  (unless (= (f1) 4.999994999999997e+7) (format *stderr* "f1 ~A\n" (f1)))
  (unless (= (f2) 4.999994999999997e+7) (format *stderr* "f2 ~A\n" (f2)))
  (unless (= (f3) 4.999994999999997e+7) (format *stderr* "f3 ~A\n" (f3)))
  (unless (= (f4) 6) (format *stderr* "f4 ~A\n" (f4)))
  (unless (= (f5) 4.999994999999997e+7) (format *stderr* "f5 ~A\n" (f5)))
  (unless (= (f6) 4.999994999999997e+7) (format *stderr* "f6 ~A\n" (f6)))
  (unless (= (f8) 4.999994999999997e+7) (format *stderr* "f8 ~A\n" (f8)))
  (unless (= (f9) 4.999994999999997e+7) (format *stderr* "f9 ~A\n" (f9)))
  (unless (= (f10) 4.999994999999997e+7) (format *stderr* "f10 ~A\n" (f10)))
  (unless (= (f11) 4.999994999999997e+7) (format *stderr* "f11 ~A\n" (f11)))
  (unless (= (f12) 4.999994999999997e+7) (format *stderr* "f12 ~A\n" (f12)))
  (unless (= (f13) 4.999994999999997e+7) (format *stderr* "f13 ~A\n" (f13)))
  (unless (= (f14) 4.999994999999997e+7) (format *stderr* "f14 ~A\n" (f14)))
  (unless (= (f15) 4.999994999999997e+7) (format *stderr* "f15 ~A\n" (f15)))
  (unless (= (f16) 4.999994999999997e+7) (format *stderr* "f16 ~A\n" (f16)))
  (unless (= (f17) 4.999994999999997e+7) (format *stderr* "f17 ~A\n" (f17)))
  (unless (= (f18) 4.999994999999997e+7) (format *stderr* "f18 ~A\n" (f18)))
  (unless (= (f19) 4.999994999999997e+7) (format *stderr* "f19 ~A\n" (f19)))
  (unless (= (f20) 4.999994999999997e+7) (format *stderr* "f20 ~A\n" (f20)))
  (unless (= (f21) 4.999994999999997e+7) (format *stderr* "f21 ~A\n" (f21)))
  (unless (= (f22) 4.999994999999997e+7) (format *stderr* "f22 ~A\n" (f22)))

  (unless (equal? (f23) 4.999994999999997e+7) (display "f23: ") (display (f23)) (newline))
  (unless (equal? (f24) 4.999994999999997e+7) (display "f24: ") (display (f24)) (newline))
  (unless (equal? (f24a) 499999500104.7288) (display "f24a: ") (display (f24a)) (newline))
  (unless (equal? (f24b) 499999500104.7288) (display "f24b: ") (display (f24b)) (newline))
  (unless (equal? (f24c) 'error) (display "f24c: ") (display (f24c)) (newline))
  (unless (equal? (f24d) 'error) (display "f24d: ") (display (f24d)) (newline))
  (unless (equal? (f25) 499999500104.7288) (display "f25: ") (display (f25)) (newline))
  (unless (equal? (f26) 6.666661664588418e+8) (display "f26: ") (display (f26)) (newline))
  (unless (equal? (f27) 9999.999999994685) (display "f27: ") (display (f27)) (newline))
  (unless (equal? (f28) 1000000.0) (display "f28: ") (display (f28)) (newline))
  (unless (equal? (f29) 1.0000090000133294e+5) (display "f29: ") (display (f29)) (newline))
  (unless (equal? (f30) 2.0000180000266587e+5) (display "f30: ") (display (f30)) (newline))
  (unless (equal? (f31) 1000000.0) (display "f31: ") (display (f31)) (newline))
  (unless (equal? (f32) 1000000.0) (display "f32: ") (display (f32)) (newline))
  (unless (equal? (f32a) 1000000.0) (display "f32a: ") (display (f32a)) (newline))
  (unless (equal? (f33) 500000.5) (display "f33: ") (display (f33)) (newline))
  (unless (equal? (f34) 1000000) (display "f34: ") (display (f34)) (newline))
  (unless (equal? (f34a) 1000001.0) (display "f34a: ") (display (f34a)) (newline))
  (unless (equal? (f35) 1000000) (display "f35: ") (display (f35)) (newline))
  (unless (equal? (f35a) 999999) (display "f35a: ") (display (f35a)) (newline))
  (unless (equal? (f35b) 0) (display "f35b: ") (display (f35b)) (newline))
  (unless (equal? (f35c) 1000000) (display "f35c: ") (display (f35c)) (newline))
  (unless (equal? (f35d) 999999) (display "f35d: ") (display (f35d)) (newline))
  (unless (equal? (f35e) 0) (display "f35e: ") (display (f35e)) (newline))
  (unless (equal? (f35f) 999999) (display "f35f: ") (display (f35f)) (newline))
  (unless (equal? (f35g) 0) (display "f35g: ") (display (f35g)) (newline))
  (unless (equal? (f35h) 999999) (display "f35h: ") (display (f35h)) (newline))
  (unless (equal? (f35i) 0) (display "f35i: ") (display (f35i)) (newline))
)

(test-all)

(exit)
