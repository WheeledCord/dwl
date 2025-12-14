(when (provided? 'pure-s7)
  (define-macro (cond-expand . clauses)
    (letrec ((traverse (lambda (tree)
			 (if (pair? tree)
			     (cons (traverse (car tree))
				   (if (null? (cdr tree)) () (traverse (cdr tree))))
			     (if (memq tree '(and or not else))
				 tree
				 (and (symbol? tree) (provided? tree)))))))
      `(cond ,@(map (lambda (clause)
		      (cons (traverse (car clause))
			    (if (null? (cdr clause)) '(#f) (cdr clause))))
		    clauses)))))


(load "s7test-block.so" (sublet (curlet) (cons 'init_func 'block_init))) ; load calls init_func if possible

(load "mockery.scm")

(define-constant one 1)

(define mock-number (*mock-number* 'mock-number))
(define mock-pair (*mock-pair* 'mock-pair))
(define mock-string (*mock-string* 'mock-string))
(define mock-char (*mock-char* 'mock-char))
(define mock-vector (*mock-vector* 'mock-vector))
(define mock-symbol (*mock-symbol* 'mock-symbol))
(define mock-hash-table (*mock-hash-table* 'mock-hash-table))

;;(openlet (inlet 'i 0 'list-set! (lambda (l . args) (apply #_list-set! l ((car args) 'i) (cdr args))))))

(define-constant constants (vector #f #t () #\a (/ (*s7* 'most-positive-fixnum)) (/ -1 (*s7* 'most-positive-fixnum)) 1.5+i 
			  "hi455" "\n  \t\x65;" :key hi: 'hi (list 1) (list 1 2) (cons 1 2) (list (list 1 2)) (list (list 1)) (list ()) #() 
			  1/0+i 0+0/0i 0+1/0i 1+0/0i 0/0+0i 0/0+0/0i 1+1/0i 0/0+i cons ''2 
			  1024 -1024 10000 10001 30000 512 -512 
			  1+i 1+1e10i 1e15+1e15i 0+1e18i 1e18 #\xff (string #\xff) 1e308 
			  (*s7* 'most-positive-fixnum) (*s7* 'most-negative-fixnum) (- (*s7* 'most-positive-fixnum) 1) (+ (*s7* 'most-negative-fixnum) 1)
			  -1 0 0.0 1 1.5 1.0-1.0i 3/4 #\null -63 (make-hash-table) (hash-table '(a . 2) '(b . 3))
			  '((1 2) (3 4)) '((1 (2)) (((3) 4))) "" (list #(1) "1") '(1 2 . 3) (list (cons 'a 2) (cons 'b 3))
			  #(1 2) (vector 1 '(3)) (let ((x 3)) (lambda (y) (+ x y))) abs 'a 'b one apply 
			  (lambda args args) (lambda* ((a 3) (b 2)) (+ a b)) (lambda () 3)
			  (sublet (rootlet) (cons 'a 1))
			  *load-hook*  *error-hook* (random-state 123)
			  quasiquote macroexpand cond-expand begin let letrec* if case cond (call-with-exit (lambda (goto) goto))
			  (with-baffle (call/cc (lambda (cc) cc)))
			  (string #\a #\null #\b) #2d((1 2) (3 4)) (inlet 'a 2 'b 3)
			  #<undefined> #<unspecified> (make-int-vector 3) (make-float-vector 3 -1.4)
			  (make-vector '(2 3) "hi") #("hiho" "hi" "hoho") (subvector (make-int-vector '(2 3) 1) 0 6)
			  (subvector (subvector (make-float-vector '(2 3) 1.0) 0 6) 0 4 '(2 2))
			  (vector-ref #2d((#(1 2 3)) (#(3 4 5))) 0 0) (define-macro (m a) `(+ ,a 1))
			  (c-pointer 0) (c-pointer -1) :readable else (define-bacro* (m (a 1)) `(+ ,a 1))
			  (byte-vector 0 1 2) (byte-vector) (byte-vector 255 0 127) (make-iterator (vector '(a . 2)))
			  (lambda (dir) 1.0) (float-vector) (make-float-vector '(2 2)) (int-vector 1 2 3) (int-vector)
			  (inlet 'value 1 '+ (lambda args 1)) (inlet) (make-iterator (inlet 'a 1 'b 2) (cons #f #f))
			  (make-iterator "123456") (make-iterator '(1 2 3)) (make-iterator (hash-table 'a 1 'b 2) (cons #f #f))
			  (open-input-string "123123") (open-input-file "/home/bil/cl/4.aiff")
			  (open-output-file "test.test") (open-output-string)
			  
			  ;(mock-number 0) (mock-number 2) (mock-number 1-i) (mock-number 4/3) (mock-number 2.0)
			  (mock-string #\h #\o #\h #\o)
			  (mock-pair '(2 3 4))
			  (mock-char #\b)
			  (mock-symbol 'c)
			  (mock-vector 1 2 3 4)
			  (mock-hash-table 'b 2)
			  
			  (make-block 4) (block) (make-iterator (block 1 2 3 4))
			  ))
(define-constant constants-len (length constants))

(define-constant ctrl-chars (string ;#\A #\S #\C #\F #\E #\G #\O #\D #\B #\X #\W
		    #\, #\{ #\} #\@ #\P #\*
		    #\a #\s #\c #\f #\e #\g #\o #\d #\b #\x #\p #\n #\w
		    #\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9
		    #\~ #\T #\& #\% #\^ #\|
		    #\~ #\~ #\~ #\~ 
		    #\, #\, #\, #\, #\" #\" #\\ #\'
		    #\+ #\- #\@ #\. #\/ #\; #\:
		    ))
(define-constant ctrl-chars-len (length ctrl-chars))

(define (test-calls ctrl-str tries size1 op)
  (do ((i 0 (+ i 1))
       (x #f) (y #f) (z #f) (pos 0)
       (cs constants)
       (cs-len constants-len))
      ((= i tries))
    (do ((j 1 (+ j 1)))
	((= j size1))
      (string-set! ctrl-str j (string-ref ctrl-chars (random ctrl-chars-len))))
    
    (set! x (vector-ref cs (random cs-len)))
    (set! y (vector-ref cs (random cs-len)))
    (set! z (vector-ref cs (random cs-len)))
    
    (object->string x)
    (display x op)
    
    (catch #t (lambda () (format #f "~{~^~S ~} ~{~|~S ~} ~W" x y z)) (lambda arg 'error))
    (catch #t (lambda () (format #f ctrl-str)) (lambda arg 'error))
    (catch #t (lambda () (format #f ctrl-str x)) (lambda arg 'error))
    (catch #t (lambda () (format #f ctrl-str y)) (lambda arg 'error))
    (catch #t (lambda () (format #f ctrl-str z)) (lambda arg 'error))
    (set! pos (char-position #\~ ctrl-str 1))
    (when pos
      (catch #t (lambda () (format #f ctrl-str x z)) (lambda arg 'error))
      (catch #t (lambda () (format #f ctrl-str x y)) (lambda arg 'error))
      (catch #t (lambda () (format #f ctrl-str y z)) (lambda arg 'error))
      (catch #t (lambda () (format #f ctrl-str z x)) (lambda arg 'error))
      (when (char-position #\~ ctrl-str (+ pos 1))
	(catch #t (lambda () (format #f ctrl-str x y z)) (lambda arg 'error))
	(catch #t (lambda () (format #f ctrl-str z y x)) (lambda arg 'error))))))

(define (test-chars)
  (let ((op (open-output-string))
	(total-size 15))
    (do ((size 2 (+ size 1))
	 (size1 3 (+ size1 1))
	 (tries 4000 (+ tries 2000))
	 (ctrl-str (make-string (+ total-size 1) #\space)))
	((= size total-size))
      (format *stderr* "~D " size)
      (string-set! ctrl-str size1 #\null)
      (string-set! ctrl-str 0 #\~)
      (test-calls ctrl-str tries size1 op)
      (get-output-string op #t))
    (close-output-port op)))

;(test-chars)

(define (f)
  (do ((i 0 (+ i 1)))
      ((= i 100000))
    (format #f "~{.~{~A~}+~{~A~}~}" '((1 2) (3 4 5) (6 7 8) (9)))
    (format #f "~{.~{+~{-~W~}~}~}" '(((1 2) (3 4 5))))
    (format #f "~{.~{+~{-~A~}~}~}" '(((1 2) (3 4 5)) ((6) (7 8 9))))
    (format #f "~9,9F" 3.14)
    (format #f "~19,'xf" 3.14)
    (format #f "~{~{~~~{~D~| ~}~| ~}~}" '(((1 2) (3 4))))
    (format #f "~10,'\\T~&~20Tasdf~&")
    (format #f "~D~*~Ctwo~P ~O ~X ~B ~,3E ~1,4F ~N,G" 23 32 #\a 2 95 95 9 pi pi 3 pi)
    ))
;(f)


;;; --------------------------------------------------------------------------------

(define size 500000)

(define (f1) ; [116] -> [78] (fixed c_function_chooser) -> [54] opt_p_call_cc
  (let ((str ""))
    (do ((i 0 (+ i 1)))
	((= i size) str)
      (set! str (format #f "just a bare string!"))))) ; ~% is turned into \n so that doesn't cost anything

;(unless (string=? (f1) "just a bare string!") (format *stderr* "f1: ~S~%" (f1)))

#|
15,951,020  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
11,000,000  s7.c:opt_p_call_cc [/home/bil/motif-snd/repl]
 9,000,000  s7.c:g_format_just_control_string [/home/bil/motif-snd/repl]
 9,000,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
 6,895,119  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
|#


(define (f2) ; [309] -> [277 opt_p_call_ccs]
  (let ((str "asdf")
	(res ""))
    (do ((i 0 (+ i 1)))
	((= i size) res)
      (set! res (format #f "~a" str))))) ; isn't this just copy? (for a string) and opt_p_call_ccs

;(unless (string=? (f2) "asdf") (format *stderr* "f2: ~S~%" (f2)))

#|
67,538,352  s7.c:s7_object_to_string [/home/bil/motif-snd/repl]
46,000,000  s7.c:string_to_port [/home/bil/motif-snd/repl]
36,000,164  s7.c:block_to_string [/home/bil/motif-snd/repl]
29,103,257  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
24,000,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
15,951,020  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
15,149,728  memcpy
15,000,000  s7.c:g_format_as_objstr [/home/bil/motif-snd/repl]
15,000,000  s7.c:opt_p_call_ccs [/home/bil/motif-snd/repl]
 9,000,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#


(define (f3) ; [469]
  (let ((str "asdf")
	(res ""))
    (do ((i 0 (+ i 1)))
	((= i size) res)
      (set! res (format #f "str: ~A" str))))) ; maybe extend g_format_as_objstr to include prestring?

;(unless (string=? (f3) "str: asdf") (format *stderr* "f3: ~S~%" (f3)))

#|
237,610,187  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 46,000,000  s7.c:string_to_port [/home/bil/motif-snd/repl]
 30,149,775  memcpy
 29,103,615  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 29,000,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
 24,000,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
 21,001,261  strchr
 15,951,020  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
 15,000,000  s7.c:opt_p_call_ccs [/home/bil/motif-snd/repl]
  9,000,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#


(define (f4) ; [717]
  (let ((str "asdf")
	(res ""))
    (do ((i 0 (+ i 1)))
	((= i size) res)
      (set! res (format #f "str: ~A ~C" str (string-ref str 0))))))

;(unless (string=? (f4) "str: asdf a") (format *stderr* "f4: ~S~%" (f4)))

#|
333,610,119  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 71,000,000  s7.c:opt_p_call_any [/home/bil/motif-snd/repl]         ; ccsc ideally
 46,149,893  memcpy
 46,000,000  s7.c:string_to_port [/home/bil/motif-snd/repl]
 42,001,811  strchr
 29,104,716  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 29,000,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
 24,000,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
 18,000,000  s7.c:string_write_char [/home/bil/motif-snd/repl]
 15,951,020  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
 10,000,000  s7.c:string_ref_p_pi_unchecked [/home/bil/motif-snd/repl]    ; str not set so string-ref is constant
  9,000,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
  8,000,000  s7.c:opt_p_pi_sc [/home/bil/motif-snd/repl]      ; calls string_ref_p_pi_unchecked
  6,002,360  ?
  6,000,000  format_to_port_1?
  6,000,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]          ; for opt_p_pi_sc!  why not just embed it?
  4,000,098  ?
  4,000,004  ./ctype/../include/ctype.h:__ctype_b_loc [/usr/lib/x86_64-linux-gnu/libc.so.6]
  4,000,000  s7.c:opt_p_s [/home/bil/motif-snd/repl]
|#


(define (f5) ; [666]
  (let ((str (list 1 2 3))
	(res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "(~{~A~^ ~})" str)))))

;(unless (string=? (f5) "(1 2 3)") (format *stderr* "f5: ~S~%" (f5)))

#|
256,000,000  s7.c:format_to_port_1'2 [/home/bil/motif-snd/repl]
204,109,962  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 58,500,000  s7.c:integer_to_port [/home/bil/motif-snd/repl]
 27,000,000  s7.c:string_write_char [/home/bil/motif-snd/repl]
 15,650,121  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
 15,000,000  /usr/include/x86_64-linux-gnu/bits/string_fortified.h:integer_to_port
 14,500,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
 14,113,341  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 12,000,584  s7.c:s7_list_length [/home/bil/motif-snd/repl]
 11,000,000  s7.c:object_to_list [/home/bil/motif-snd/repl]
 10,502,830  ./string/../sysdeps/x86_64/multiarch/strchr-avx2.S:__strchr_avx2 [/usr/lib/x86_64-linux-gnu/libc.so.6]
  7,950,972  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  7,500,000  s7.c:opt_p_call_ccs [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#


(define (f6) ; [943]
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~1,4F" pi)))))

;(unless (string=? (f6) "3.1416") (format *stderr* "f6: ~S~%" (f6)))

#|
225,500,000  ./stdio-common/./stdio-common/printf_fp.c:__printf_fp_buffer_1.constprop.0.isra.0 [/usr/lib/x86_64-linux-gnu/libc.so.6]
122,109,960  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
114,524,056  ./stdio-common/./stdio-common/vfprintf-internal.c:__printf_buffer [/usr/lib/x86_64-linux-gnu/libc.so.6]
 63,000,000  ./stdlib/../sysdeps/x86_64/mul_1.S:__mpn_mul_1 [/usr/lib/x86_64-linux-gnu/libc.so.6]
 40,000,000  s7.c:format_numeric_arg [/home/bil/motif-snd/repl]
 36,519,357  ./stdio-common/./stdio-common/Xprintf_buffer_write.c:__printf_buffer_write [/usr/lib/x86_64-linux-gnu/libc.so.6]
 32,500,012  s7.c:number_to_string_base_10.isra.0 [/home/bil/motif-snd/repl]
 30,500,000  s7.c:format_number [/home/bil/motif-snd/repl]
 27,500,000  ./stdio-common/./stdio-common/printf_fp.c:__printf_fp_l_buffer [/usr/lib/x86_64-linux-gnu/libc.so.6]
 25,000,000  ./stdio-common/./stdio-common/printf_fp.c:hack_digit [/usr/lib/x86_64-linux-gnu/libc.so.6]
 19,507,657  ./debug/./debug/snprintf_chk.c:__snprintf_chk [/usr/lib/x86_64-linux-gnu/libc.so.6]
 19,009,424  ./string/../sysdeps/x86_64/multiarch/strchr-avx2.S:__strchrnul_avx2 [/usr/lib/x86_64-linux-gnu/libc.so.6]
 15,149,924  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
 14,500,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
 14,113,761  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 14,006,916  ./libio/./libio/vsnprintf.c:__vsnprintf_internal [/usr/lib/x86_64-linux-gnu/libc.so.6]
 12,000,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
 11,000,000  ./stdlib/../sysdeps/ieee754/dbl-64/dbl2mpn.c:__mpn_extract_double [/usr/lib/x86_64-linux-gnu/libc.so.6]
 10,503,772  ./string/../sysdeps/x86_64/multiarch/strchr-avx2.S:__strchr_avx2 [/usr/lib/x86_64-linux-gnu/libc.
|#

(define (f6a) ; 918
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~F" pi)))))

;(unless (string=? (f6a) "3.141593") (format *stderr* "f6a: ~S~%" (f6a)))

#|
254,500,000  ./stdio-common/./stdio-common/printf_fp.c:__printf_fp_buffer_1.constprop.0.isra.0 [/usr/lib/x86_64-linux-gnu/libc.so.6]
103,037,242  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 97,524,056  ./stdio-common/./stdio-common/vfprintf-internal.c:__printf_buffer [/usr/lib/x86_64-linux-gnu/libc.so.6]
 84,000,000  ./stdlib/../sysdeps/x86_64/mul_1.S:__mpn_mul_1 [/usr/lib/x86_64-linux-gnu/libc.so.6]
 36,519,357  ./stdio-common/./stdio-common/Xprintf_buffer_write.c:__printf_buffer_write [/usr/lib/x86_64-linux-gnu/libc.so.6]
 33,000,012  s7.c:number_to_string_base_10.isra.0 [/home/bil/motif-snd/repl]
 32,500,000  s7.c:format_number [/home/bil/motif-snd/repl]
 27,500,000  ./stdio-common/./stdio-common/printf_fp.c:__printf_fp_l_buffer [/usr/lib/x86_64-linux-gnu/libc.so.6]
 25,000,000  ./stdio-common/./stdio-common/printf_fp.c:hack_digit [/usr/lib/x86_64-linux-gnu/libc.so.6]
 19,507,657  ./debug/./debug/snprintf_chk.c:__snprintf_chk [/usr/lib/x86_64-linux-gnu/libc.so.6]
 19,009,424  ./string/../sysdeps/x86_64/multiarch/strchr-avx2.S:__strchrnul_avx2 [/usr/lib/x86_64-linux-gnu/libc.so.6]
 14,705,606  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
|#

(define (f6b) ; 598
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~,16G" pi))))) ; 16=write_real_precision

;(unless (string=? (f6b) "3.141592653589793") (format *stderr* "f6b: ~S~%" (f6b)))

#|
290,000,012  s7.c:number_to_string_base_10.isra.0 [/home/bil/motif-snd/repl]
114,036,766  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 43,500,000  s7.c:dtoa_multiply.isra.0 [/home/bil/motif-snd/repl]
 30,500,000  s7.c:format_number [/home/bil/motif-snd/repl]
 26,500,000  s7.c:format_numeric_arg [/home/bil/motif-snd/repl]
 20,163,329  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
 14,705,113  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 14,500,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
 12,500,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
  7,950,981  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  7,500,000  s7.c:opt_p_call_ccs [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#

(define (f6c) ; 436
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (number->string pi)))))

;(unless (string=? (f6c) "3.141592653589793") (format *stderr* "f6c: ~S~%" (f6c)))

#|
290,000,012  s7.c:number_to_string_base_10.isra.0 [/home/bil/motif-snd/repl]
 43,500,000  s7.c:dtoa_multiply.isra.0 [/home/bil/motif-snd/repl]
 38,289,362  s7.c:number_to_string_p_p [/home/bil/motif-snd/repl]
 20,163,183  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
 14,705,178  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
  7,950,981  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
  3,500,000  s7.c:opt_p_p_s [/home/bil/motif-snd/repl]
|#

(define (f6d) ; 567
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~A" (number->string pi))))))

;(unless (string=? (f6d) "3.141592653589793") (format *stderr* "f6d: ~S~%" (f6d)))

#|
290,000,012  s7.c:number_to_string_base_10.isra.0 [/home/bil/motif-snd/repl]
 43,500,000  s7.c:dtoa_multiply.isra.0 [/home/bil/motif-snd/repl]
 38,026,806  s7.c:number_to_string_p_p [/home/bil/motif-snd/repl]
 33,815,277  s7.c:s7_object_to_string [/home/bil/motif-snd/repl]
 25,673,295  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 25,663,099  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
 23,000,000  s7.c:string_to_port [/home/bil/motif-snd/repl]
 18,000,075  s7.c:block_to_string [/home/bil/motif-snd/repl]
 18,000,000  s7.c:opt_p_call_ppp [/home/bil/motif-snd/repl]
 12,500,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
  7,951,065  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  4,500,000  s7.c:g_format_as_objstr [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#

(define (f7) ; [362]
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~D is ~:D" 3 3)))))

;(unless (string=? (f7) "3 is third") (format *stderr* "f7: ~S~%" (f7)))

#|
151,609,892  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 35,500,000  s7.c:format_number [/home/bil/motif-snd/repl]
 35,500,000  s7.c:opt_p_call_any [/home/bil/motif-snd/repl]
 24,000,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
 23,500,012  s7.c:number_to_string_base_10.isra.0 [/home/bil/motif-snd/repl]
 23,149,965  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
 14,500,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
 14,114,301  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 10,503,830  ./string/../sysdeps/x86_64/multiarch/strchr-avx2.S:__strchr_avx2 [/usr/lib/x86_64-linux-gnu/libc.so.6]
  7,950,930  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  6,000,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#


(define (f8) ; [375]
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~ND" 20 1234)))))  ; "width field so string is 20 wide

;(unless (string=? (f8) "                1234") (format *stderr* "f8: ~S~%" (f8)))

#|
114,109,824  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 37,500,000  s7.c:integer_to_string [/home/bil/motif-snd/repl]
 35,500,000  s7.c:format_number [/home/bil/motif-snd/repl]
 35,500,000  s7.c:opt_p_call_any [/home/bil/motif-snd/repl]
 27,500,012  s7.c:number_to_string_base_10.isra.0 [/home/bil/motif-snd/repl]
 21,000,000  s7.c:local_memset [/home/bil/motif-snd/repl]
 14,500,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
 14,114,316  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 13,500,000  s7.c:insert_spaces [/home/bil/motif-snd/repl]
 13,149,880  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
 12,000,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
  8,500,000  s7.c:format_n_arg [/home/bil/motif-snd/repl]
  7,950,930  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  6,000,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#


(define (f9) ; [424]
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~NC~D" 20 #\space 1234)))))  ; 20 spaces then 1234

;(unless (string=? (f9) "                    1234") (format *stderr* "f9: ~S~%" (f9)))

#|
146,609,756  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 39,500,000  s7.c:opt_p_call_any [/home/bil/motif-snd/repl]
 37,500,000  s7.c:integer_to_string [/home/bil/motif-snd/repl]
 35,500,000  s7.c:format_number [/home/bil/motif-snd/repl]
 35,500,000  s7.c:local_memset [/home/bil/motif-snd/repl]
 24,000,012  s7.c:number_to_string_base_10.isra.0 [/home/bil/motif-snd/repl]
 18,500,000  s7.c:format_append_chars [/home/bil/motif-snd/repl]
 14,500,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
 14,114,451  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 12,000,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
  8,500,000  s7.c:format_n_arg [/home/bil/motif-snd/repl]
  7,950,930  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  7,650,071  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
  7,500,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#


(define (f10) ; [768]
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~{~C~^ ~}" "hiho")))))

;(unless (string=? (f10) "h i h o") (format *stderr* "f10: ~S~%" (f10)))

#|
367,000,000  s7.c:format_to_port_1'2 [/home/bil/motif-snd/repl]
189,703,539  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 63,000,000  s7.c:string_write_char [/home/bil/motif-snd/repl]
 42,500,000  s7.c:object_to_list [/home/bil/motif-snd/repl]
 29,094,117  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 18,000,000  s7.c:opt_p_call_ppp [/home/bil/motif-snd/repl]
 14,500,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
  8,000,004  ./ctype/../include/ctype.h:__ctype_b_loc [/usr/lib/x86_64-linux-gnu/libc.so.6]
  7,950,930  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  7,650,227  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
  4,500,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
  4,000,002  ???:0x0000000000116e20 [???]
  3,000,000  s7.c:check_free_heap_size [/home/bil/motif-snd/repl]
|#


(define (f11) ; [345]
  (let ((res "")
	(size10 (/ size 10)))
    (do ((i 0 (+ i 1)))
	((= i size10) res)
      (set! res (format #f "~{~{~C~^ ~}~^...~}" (list "hiho" "test"))))))

;(unless (string=? (f11) "h i h o...t e s t") (format *stderr* "f11: ~S~%" (f11)))

#|
217,500,010  s7.c:format_to_port_1'2 [/home/bil/motif-snd/repl]
 39,898,225  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 25,200,000  s7.c:string_write_char [/home/bil/motif-snd/repl]
 19,200,000  s7.c:object_to_list [/home/bil/motif-snd/repl]
  9,714,210  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
  6,184,807  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
  3,600,000  s7.c:opt_p_call_ppp [/home/bil/motif-snd/repl]
  3,200,004  ./ctype/../include/ctype.h:__ctype_b_loc [/usr/lib/x86_64-linux-gnu/libc.so.6]
  2,900,085  s7.c:list_p_pp [/home/bil/motif-snd/repl]
  2,900,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
  2,108,641  ./string/../sysdeps/x86_64/multiarch/strchr-avx2.S:__strchr_avx2 [/usr/lib/x86_64-linux-gnu/libc.so.6]
  1,900,692  s7.c:s7_list_length [/home/bil/motif-snd/repl]
  1,600,002  ???:0x0000000000116e20 [???]
  1,550,930  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  1,200,000  s7.c:check_free_heap_size [/home/bil/motif-snd/repl]
    900,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
    802,400  ???:0x0000000000116b00 [???]
    700,000  /usr/include/x86_64-linux-gnu/bits/string_fortified.h:format_to_port_1'2
    700,000  s7.c:opt_p_pp_cc [/home/bil/motif-snd/repl]
    600,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]
|#


(define (f12) ; [443]
  (let-temporarily (((*s7* 'print-length) 4))
    (let ((res "")
	  (size4 (/ size 4)))
      (do ((i 0 (+ i 1)))
	  ((= i size4) res)
	(set! res (format #f "~{~A~| ~}" #(0 1 2 3 4 5 6 7 8)))))))

;(unless (string=? (f12) "0 1 2 3 ...") (format *stderr* "f12: ~S~%" (f12)))

#|
178,750,000  s7.c:format_to_port_1'2 [/home/bil/motif-snd/repl]
 94,858,241  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 39,000,000  s7.c:integer_to_port [/home/bil/motif-snd/repl]
 32,750,000  s7.c:s7_vector_to_list [/home/bil/motif-snd/repl]
 23,501,027  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 13,500,000  s7.c:string_write_char [/home/bil/motif-snd/repl]
 10,000,000  /usr/include/x86_64-linux-gnu/bits/string_fortified.h:integer_to_port
  9,000,000  s7.c:opt_p_call_ppp [/home/bil/motif-snd/repl]
  7,584,709  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
  7,250,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
  6,500,000  s7.c:object_to_list [/home/bil/motif-snd/repl]
  6,000,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
  3,950,936  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  2,250,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]
  2,250,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
  1,500,000  s7.c:check_free_heap_size [/home/bil/motif-snd/repl]
|#


(define (f13) ; [352]
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~B" 1234)))))

;(unless (string=? (f13) "10011010010") (format *stderr* "f13: ~S~%" (f13)))

#|
108,000,144  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 78,500,000  s7.c:integer_to_string_any_base [/home/bil/motif-snd/repl]
 43,000,000  s7.c:format_number [/home/bil/motif-snd/repl]
 32,967,791  s7.c:number_to_string_with_radix [/home/bil/motif-snd/repl]
 18,000,000  s7.c:opt_p_call_ppp [/home/bil/motif-snd/repl]
 14,500,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
 14,114,539  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 12,000,000  s7.c:string_write_string [/home/bil/motif-snd/repl]
  7,950,972  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  6,781,191  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
  4,500,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#


(define (f14) ; [357]
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~A ~* ~A" 1 2 3)))))

;(unless (string=? (f14) "1  3") (format *stderr* "f14: ~S~%" (f14)))

#|
173,609,289  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 39,500,000  s7.c:opt_p_call_any [/home/bil/motif-snd/repl]
 39,000,000  s7.c:integer_to_port [/home/bil/motif-snd/repl]
 21,011,634  ./string/../sysdeps/x86_64/multiarch/strchr-avx2.S:__strchr_avx2 [/usr/lib/x86_64-linux-gnu/libc.so.6]
 16,281,614  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
 14,500,000  s7.c:g_format_no_column [/home/bil/motif-snd/repl]
 14,114,923  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 10,000,000  /usr/include/x86_64-linux-gnu/bits/string_fortified.h:integer_to_port
  7,950,972  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  7,500,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#


(define (f15) ; [478]
  (let ((res "")
	(size2 (/ size 2)))
    (do ((i 0 (+ i 1)))
	((= i size2) res)
      (set! res (format #f "~A:~8T~A" 100 'a)))))

;(unless (string=? (f15) "100:   a") (format *stderr* "f15: ~S~%" (f15)))

#|
217,609,212  s7.c:format_to_port_1 [/home/bil/motif-snd/repl]
 35,500,000  s7.c:opt_p_call_any [/home/bil/motif-snd/repl]
 33,150,402  ./string/../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:__memcpy_avx_unaligned_erms [/usr/lib/x86_64-linux-gnu/libc.so.6]
 24,000,024  s7.c:string_write_string [/home/bil/motif-snd/repl]
 21,000,000  s7.c:format_numeric_arg [/home/bil/motif-snd/repl]
 19,500,012  s7.c:integer_to_port [/home/bil/motif-snd/repl]
 18,500,000  s7.c:format_append_chars [/home/bil/motif-snd/repl]
 18,000,037  s7.c:symbol_to_port [/home/bil/motif-snd/repl]
 15,500,000  s7.c:local_memset [/home/bil/motif-snd/repl]
 14,114,921  s7.c:gc.isra.0 [/home/bil/motif-snd/repl]
 10,512,314  ./string/../sysdeps/x86_64/multiarch/strchr-avx2.S:__strchr_avx2 [/usr/lib/x86_64-linux-gnu/libc.so.6]
  9,500,000  s7.c:g_format_f [/home/bil/motif-snd/repl]
  7,950,972  s7.c:opt_dotimes [/home/bil/motif-snd/repl]
  6,500,001  /usr/include/x86_64-linux-gnu/bits/string_fortified.h:integer_to_port
  6,000,000  s7.c:opt_p_c [/home/bil/motif-snd/repl]
  4,500,000  s7.c:opt_set_p_p_f [/home/bil/motif-snd/repl]
|#


(define (test-all)
  (test-chars)
  (f)
  (unless (string=? (f1) "just a bare string!") (format *stderr* "f1: ~S~%" (f1)))
  (unless (string=? (f2) "asdf") (format *stderr* "f2: ~S~%" (f2)))
  (unless (string=? (f3) "str: asdf") (format *stderr* "f3: ~S~%" (f3)))
  (unless (string=? (f4) "str: asdf a") (format *stderr* "f4: ~S~%" (f4)))
  (unless (string=? (f5) "(1 2 3)") (format *stderr* "f5: ~S~%" (f5)))
  (unless (string=? (f6) "3.1416") (format *stderr* "f6: ~S~%" (f6)))
  (unless (string=? (f6a) "3.141593") (format *stderr* "f6a: ~S~%" (f6a)))
  (unless (string=? (f6b) "3.141592653589793") (format *stderr* "f6b: ~S~%" (f6b)))
  (unless (string=? (f6c) "3.141592653589793") (format *stderr* "f6c: ~S~%" (f6c)))
  (unless (string=? (f6d) "3.141592653589793") (format *stderr* "f6d: ~S~%" (f6d)))
  (unless (string=? (f7) "3 is third") (format *stderr* "f7: ~S~%" (f7)))
  (unless (string=? (f8) "                1234") (format *stderr* "f8: ~S~%" (f8)))
  (unless (string=? (f9) "                    1234") (format *stderr* "f9: ~S~%" (f9)))
  (unless (string=? (f10) "h i h o") (format *stderr* "f10: ~S~%" (f10)))
  (unless (string=? (f11) "h i h o...t e s t") (format *stderr* "f11: ~S~%" (f11)))
  (unless (string=? (f13) "10011010010") (format *stderr* "f13: ~S~%" (f13)))
  (unless (string=? (f14) "1  3") (format *stderr* "f14: ~S~%" (f14)))
  (unless (string=? (f15) "100:   a") (format *stderr* "f15: ~S~%" (f15)))
  )

(test-all) ; 9455

(when (> (*s7* 'profile) 0)
  (show-profile 200))
(exit)

