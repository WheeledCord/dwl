;;; this is an extension of tauto.scm, an auto-tester

(define with-mock-data #f)
;(set! (*s7* 'profile) 1)
(when (provided? 'number-separator) (set! (*s7* 'number-separator) #\,))
;(set! (*s7* 'gc-stats) 4) ; stack-stats
(set! (*s7* 'float-format-precision) 4)
(set! *stdin* #f)

(unless (defined? 'fuzzies)
  (define fuzzies 100000))

(define with-continuations #t)

(for-each (lambda (x)
	    (unless (memq (car x) '(*features* *libraries* *#readers*)) ; last 2 for sandbox
	      (immutable! (car x))))
	  (rootlet))

(for-each (lambda (x)
	    (when (syntax? (symbol->value x))
	      (immutable! x)
	      (immutable! (symbol->value x))))
	  (symbol-table))

(require libc.scm)

(unless (file-exists? "~/cl/tmp1.r5rs")
  (system "touch ~/cl/tmp1.r5rs"))

;(define debugging (provided? 'debugging))
;(when (provided? 'profiling) (load "profile.scm"))
;(set! (hook-functions *load-hook*) (list (lambda (hook) (format () "loading ~S...~%" (hook 'name)))))

(define-constant %features% (copy *features*))

(define (daytime)
  (with-let (sublet *libc*)
    (let ((timestr (make-string 16))
	  (p #f))
      (let ((len (strftime timestr 16 "%H:%M"
			   (localtime
			    (set! p (time.make (time (c-pointer 0 'time_t*))))))))
	(time.free p)
	(substring timestr 0 len)))))


(define (memory-rusage)
  (with-let (sublet *libc*)
    (let ((v (rusage.make)))
      (getrusage RUSAGE_SELF v)
      (let ((mem (rusage.ru_maxrss v)))
	(free v)
	(/ mem 1024.0))))) ; this is in mbytes

(define (cycler size)
  (let ((cp-lst (make-list 3 #f))
	(it-lst (make-list 3 #f)))
    (let ((bases (vector (make-list 3 #f)
			 (make-vector 3 #f)
			 (hash-table 'a 1 'b 2 'c 3)
			 (inlet 'a 1 'b 2 'c 3)
			 (make-iterator it-lst)
			 (c-pointer 1 cp-lst)))
	  (sets ()))

      (do ((blen (length bases))
	   (i 0 (+ i 1)))
	  ((= i size))
	(let ((r1 (random blen))
	      (r2 (random blen))
	      (loc (random 3)))
	  (let ((b1 (bases r1))
		(b2 (bases r2)))
	    (case (type-of b1)
	      ((pair?)
	       (if (> (random 10) 3)
		   (begin
		     (set! (b1 loc) b2)
		     (set! sets (cons (list r1 loc r2) sets)))
		   (begin
		     (set-cdr! (cddr b1) (case loc ((0) b1) ((1) (cdr b1)) (else (cddr b1))))
		     (set! sets (cons (list r1 (+ loc 3) r2) sets)))))

	      ((vector?)
	       (set! (b1 loc) b2)
	       (set! sets (cons (list r1 loc r2) sets)))

	      ((hash-table? let?)
	       (let ((key (#(a b c) loc)))
		 (set! (b1 key) b2)
		 (set! sets (cons (list r1 key r2) sets))))

	      ((c-pointer?)
	       (set! (cp-lst loc) b2)
	       (set! sets (cons (list r1 loc r2) sets)))

	      ((iterator?)
	       (set! (it-lst loc) b2)
	       (set! sets (cons (list r1 loc r2) sets)))))))

      (object->string (bases (random 6)) :readable))))

(load "stuff.scm")
(load "write.scm")

#|
(define linter (let ()
		 (let-temporarily (((*s7* 'autoloading?) #t))
		   (load "lint.scm"))
		 (lambda (str)
		   (call-with-output-string
		    (lambda (op)
		      (call-with-input-string str
			(lambda (ip)
			  (lint ip op))))))))

(define (checked-linter code)
  (or (pair? (cyclic-sequences code))
      (linter (object->string code :readable))))
|#

;;(define (pp-checked obj) (let-temporarily ((((funclet pretty-print) '*pretty-print-cycles*) #t)) (pp obj)))
;; #t is the default for print-cycles
(require case.scm)
(define match?  ((funclet 'case*) 'case*-match?))

(when with-mock-data
  (load "mockery.scm")
  (define-constant mock-number (*mock-number* 'mock-number))
  (define-constant mock-pair (*mock-pair* 'mock-pair))
  (define-constant mock-string (*mock-string* 'mock-string))
  (define-constant mock-char (*mock-char* 'mock-char))
  (define-constant mock-vector (*mock-vector* 'mock-vector))
  (define-constant mock-symbol (*mock-symbol* 'mock-symbol))
  (define-constant mock-hash-table (*mock-hash-table* 'mock-hash-table))
  (define-constant mock-c-pointer (*mock-c-pointer* 'mock-c-pointer))
  (define-constant mock-port (*mock-port* 'mock-port))
  (define-constant mock-random-state (*mock-random-state* 'mock-random-state)))

;(define-constant _mv_ (if with-mock-data (mock-vector 1 2) (vector 1 2)))
;(define-constant _v_ #(1 2))
;(define-constant _mv_ (if with-mock-data (mock-number 1) 1))
;(define-constant _v_ 1)

;(define-constant _mv_ (if with-mock-data (let ((L1 (mock-pair 1 2))) (immutable! (L1 'value))) (immutable! (list 1 2))))
;(define-constant _v_ (immutable! (list 1 2)))

(define-constant _mv_ (if with-mock-data (let ((L1 (mock-hash-table 'a 2))) (immutable! (L1 'value))) (immutable! (hash-table 'a 2))))
(define-constant _v_ (immutable! (hash-table 'a 2)))


(set! (*s7* 'safety) 2) ; protect copy (in define-expansion evaluation) from circular lists

(set! (*s7* 'max-stack-size) (* 4 32768))
(set! (*s7* 'max-heap-size) (ash 1 23)) ; 16M = 1.4Gbytes?
(set! (*s7* 'max-string-port-length) (ash 1 28))
(set! (*s7* 'print-length) 4096)
(set! (*s7* 'max-string-length) 500000)
(set! (*s7* 'max-list-length) 100000)
(set! (*s7* 'max-vector-length) 100000)
(set! (*s7* 'max-vector-dimensions) 10)
(set! (*s7* 'autoloading?) #f)
(set! (*s7* 'muffle-warnings?) #t)
(set! (*s7* 'equivalent-float-epsilon) 1.0e-6)
(set! (current-output-port) #f)

(define ostr "")
(define estr "")
(define nostr "")
(define curstr "")
(define last-func #f)

(define error-type 'no-error)
(define error-info #f)
(define error-code "")
(define-constant false #f)
(define-constant _undef_ 'a!s!d!f) ;(car (with-input-from-string "(#_asdf 1 2)" read)))
(define (kar x) (car x)) ; not the same as (define kar car) -- subsequent setter below affects car in the latter case
(set! (setter kar) (lambda (sym e) (error 'oops "kar not settable: ~A" ostr)))
(define-constant _1234_ 1234)
(define-constant _dilambda_ (dilambda (lambda (x) (+ x 1)) (lambda (x y) (+ x y))))
(define-constant _dl_ (let ((x #f)) (dilambda (lambda () x) (lambda (y) (set! x y)))))
(define __var2__ 3)
(set! (setter '__var2__) (let ((+signature+ '(boolean? #t))) (lambda (s v) (if (integer? v) v 3))))
(define _definee_ #f)
(define x 0)
(define my-let let)
(define my-with-baffle with-baffle)
(define* (my-make-byte-vector size (init 0)) (make-byte-vector size init))
(define* (my-make-string size (init #\a)) (make-string size init))

(define recall-ccr #f)
(with-baffle (set! recall-ccr (call/cc (lambda (ccr) ccr))))
(immutable! recall-ccr)
(define-constant (recall1 . args)
  (catch 
      (lambda ()
	(recall-ccr 1)
	(error 'oops (display "ccr oops" *stderr*) (newline *stderr*)))
    (lambda args 'ok)))

(define recall-ccx #f)
(call-with-exit (lambda (ccx) (set! recall-ccx ccx)))
(immutable! recall-ccx)
(define-constant (recall2 . args)
  (catch 
      (lambda ()
	(recall-ccx 1)
	(error 'oops (display "ccx oops" *stderr*) (newline *stderr*)))
    (lambda args 'ok)))

(define-constant Hk (make-hook 'x))
(set! (hook-functions Hk) (list (lambda (h)
				  (set! (h 'result) (+ (h 'x) 1)))))

(define-constant V_1 (let ((v (make-vector 8))) (set! (vector-typer v) symbol?) v))
(define-constant V_2 (let ((v (make-vector 1))) (set! (v 0) v) v))

(define-constant H_1
  (let ((H (hash-table 'v1 1 'v2 2 'v3 3))
	(last-key #f))
    (define (valtyp val)
      (or (memq last-key '(#f v1))
	  (and (eq? last-key 'v2)
	       (<= 0 val 32))))
    (define (keytyp key)
      (set! last-key key)
      #t)
    (set! (hash-table-key-typer H) keytyp)
    (set! (hash-table-value-typer H) valtyp)
    (immutable! H)))

(define-constant H_2 (immutable! (make-hash-table 8 eq? (cons symbol? integer?))))
(define-constant H_3 (immutable! (make-hash-table 8 (cons equal? hash-code))))
(define-constant H_4 (immutable! (make-hash-table 8
						  (let ((eqf (lambda (a b) (equal? a b)))
							(mapf (lambda (a) (hash-code a))))
						    (cons eqf mapf)))))
(define-constant H_5 (let ((H (make-hash-table 8
					       (let ((eqf (lambda (a b) (equal? a b)))
						     (mapf (lambda (a) (hash-code a))))
						 (cons eqf mapf))))
			   (last-key #f))
		       (define (valtyp val)
			 (or (memq last-key '(#f V_1))
			     (and (eq? last-key 'V_2)
				  (<= 0 val 32))))
		       (define (keytyp key)
			 (set! last-key key)
			 #t)
		       (set! (hash-table-key-typer H) keytyp)
		       (set! (hash-table-value-typer H) valtyp)
		       (immutable! H)))
(define-constant H_6 (let ((h (make-hash-table 8 eq? (cons symbol? hash-table?))))
		       (hash-table-set! h 'a h)
		       (immutable! h)))
(define-constant L_6 (let ((L (inlet 'a #f))) (let-set! L 'a L) (immutable! L)))

(define fvref float-vector-ref)
(define cvref complex-vector-ref)
(define ivref int-vector-ref)
(define bvref byte-vector-ref)
(define vref vector-ref)
(define ivset int-vector-set!)
(define bvset byte-vector-set!)
(define vset vector-set!)
(define adder +)

(define (_vals_) (values #f 1 2))
(define (_vals1_) (values 1 #f 2))
(define (_vals2_) (values 1 2 #f))
(define (finite? n) (not (or (nan? n) (infinite? n))))
(define (more-values) (values 1 2 3 4))
(define (_vals3_ x) (values x x))
(define (_vals4_ x y) (values x y))
(define (_vals5_ x y z) (values x y z))
(define (_vals6_ w x y z) (values w x y z))

(define* (_vals3s_ x) (values x x))
(define* (_vals4s_ x y) (values x y))
(define* (_vals5s_ x y z) (values x y z))
(define* (_vals6s_ w x y z) (values w x y z))

(define (_svals3_ x) (* x x))
(define (_svals4_ x y) (* x y))
(define (_svals5_ x y z) (* x y z))
(define (_svals6_ w x y z) (* w x y z))

(define* (_svals3s_ x) (* x x))
(define* (_svals4s_ x y) (* x y))
(define* (_svals5s_ x y z) (* x y z))
(define* (_svals6s_ w x y z) (* w x y z))

(define (fop1 x y z)
  (+ (floor (* x y)) z)) ; op_opssqq_s
(define (fop2 x y z)
  (+ (* x y) (abs z)))   ; opssq_opsq
(define (fop3 x y z)
  (+ (abs x) (* y z)))   ; opsq_opssq
(define (_h1_ x) (vector-ref x 0))
(define (_h2_ x) (vector-ref x 1))
(define (_ff_ x y) (+ (_h1_ x) (_h2_ y)))
(define (tff) (_ff_ (vector 1 2) (vector 3 4))) ; c_ff
(define (fop4 x y)       ; apply_ss
  (apply x y))
(define (fop5 x y)       ; apply_sl
  (apply x (list y)))
(define (fop6 x y)       ; apply_sa
  (apply x (cons y ())))
(define (fop7 x) (integer? x) (+ x 1))
(define (tf7 y) (fop7 y))
(define (fop8 x y) (integer? x) (+ x y))
(define (tf8 y) (fop8 y y))
(define (fop9 x y)
  (integer? x)
  (values x y))
(define (tf9 y)
  (let ((x 1))
    (fop9 x y)))
(define (tf10 x)
  (fop9 x 1))
(define fop13 ; op_closure_na
  (lambda (i s L V S H E)
    (vector (L (+ i 1)) (V (+ i 1)) (S (+ i 1)) (H (+ i 1)) (E (string->symbol s)))))
(define (tf13 x)
  (let ((L1 (list 1 2 3))
	(V1 (vector 1 2 3))
	(S1 "123")
	(H1 (hash-table 1 1 2 2 3 3))
	(E1 (inlet :a 1 :b 2)))
    (fop13 x "a" L1 V1 S1 H1 E1) (vector 2 2 #\2 1 1)))
(define* (fop14 par) ; safe_closure*_ka
  (+ par 1))
(define (tf14 x)
  (fop14 :par x))
(define (fop15 f a)   ; closure_fa
  (f a))
(define (tf15 y)
  (fop15 (lambda (x) (+ x 1)) y))
(define* (fop16 par)  ; closure_star_ka
  (fop16-1 par))
(define (tf16 x)
  (fop16 :par x))
(define (fop16-1 x) x)
(define (fop17 a b c) ; closure_3s
  (fop17-1 (+ a 1) b c))
(define (tf17 x)
  (fop17 x x x))
(define (tf18 x)      ; closure_saa
  (fop17 x (+ x 1) (* x 2)))
(define (fop17-1 a b c)
  (+ a b c))
(define (fop19 a b)   ; closure_aa
  (display a #f)
  (fop19-1 a (+ b 1)))
(define (tf19 x)
  (fop19 (* x 2) (+ x 1)))
(define (fop19-1 x y)
  (+ x y))
(define (fop20 a b)   ; cl_sas
  (map list (car a) b))
(define (tf20 x)
  (fop20 (list (list 1 2 3)) x))
(define (fop21 a b c d) ; closure_4s
  (fop21-1 (+ a 1) b c d))
(define (tf21 x)
  (fop21 x x x x))
(define (fop21-1 a b c d)
  (+ a b c d))
(define (fop22 a b)   ; apply_sl
  (apply + (list a b)))
(define (tf22 x)
  (fop22 x x))
(define (fop23 a)     ; apply_ss
  (apply + a))
(define (tf23 x)
  (fop23 x))
(define (fop24 a b c d e)
  (+ a b c d e))
(define (tf24 x)
  (fop24 (fop24-1 x) (fop24-1 (+ x 1)) x x x)) ; any_closure_np
(define (fop24-1 x)
  (* x 2))
(define (tf25 x)
  (fop24 (fop24-1 x) (fop24-1 (+ x 1)) x x (values x x))) ; any_closure_np_mv
(define (tf26 x)
  (fop24 (fop24-1 x) x (values x x x)))
(define (tf27 x)
  (fop24 (values x x x) (fop24-1 x) (fop24-1 x)))
(define (fop29 x)
  (and (int-vector? x)
       (sort! x (lambda (a b) (unless (and a b) (error "oops")) (< a b)))))
(define (fop30 a b c)
  (+ a b c))
(define (tf30 x)
  (let ((y (* x 2))
	(z (+ x 1)))
    (fop30 x y z))) ; safe_closure_3s_a
(define (fop31 a b c)
  (+ a b)
  (max a b c))
(define (tf31 x)
  (let ((y (* x 2))
	(z (+ x 1)))
    (fop31 x y z))) ; safe_closure_3s
(define (fop32-0 x) (vector-ref x 0))
(define (fop32-1 x) (vector-ref x 1))
(define (fop32 x) (+ (fop32-0 x) (fop32-1 x)))
(define (tf32 x) (fop32 x)) ; fx_c_ff = op_safe_c_ff
(define (fop33 x y) (abs y) (+ x 1))
(define (tf33 x) (fop33 x 0))  ; op_safe_closure_sc
(define* (fop34 x y) (abs y) (+ x y))
(define (tf34 x) (fop34 (+ x 1) (* x 2))) ; op_safe_closure_star_aa

(define (f40 c) ; assoc_if
  (assoc c (list (cons 1 a) (cons 2 b) (cons 3 c) (cons 4 d)) (lambda* (a b) (= a b))))
(define (f41 c) ; member_if
  (member c (list 1 2 3 4 5) (lambda* (a b) (= a b))))

(define (fequal? a b) (equal? a b))

(define (sym1 . a) (copy a))
(define (sym2 a . b) (cons a (copy b)))
(define (sym3 a b . c) (list a b (copy c)))
(define* (sym4 :rest a) (copy a))
(define* (sym5 a :rest b) (cons a (copy b)))
(define* (sym6 a b :rest c) (list a b (copy c)))
;(define* (sym7 a :rest b :rest c) (list a b c))

(define-macro (msym1 . a) `(list (list ,@a)))
(define-macro (msym2 a . b) `(cons ,a (copy ,b))) ; these are confusing!
(define-macro (msym3 a b . c) `(list ,a ,b (copy ,c)))
(define-macro* (msym4 :rest a) `(copy ,a))
(define-macro* (msym5 a :rest b) `(cons ,a (list (list ,@b))))
;(define-macro* (msym6 a b :rest c) `(list ,a ,b (copy ,c)))
;(define-macro* (msym7 a :rest b :rest c) `(list ,a ,@b ,@c))
(define-macro (msym8 a) (let ((g (gensym))) `(let ((,g ,a)) (values a a))))

(define (s7-print-length) (*s7* 'print-length))
(define (s7-max-string-length) (*s7* 'max-string-length))
(define (s7-max-list-length) (*s7* 'max-list-length))
(define (s7-max-vector-length) (*s7* 'max-vector-length))
(define (s7-max-vector-dimensions) (*s7* 'max-vector-dimensions))
(define (s7-default-hash-table-length) (*s7* 'default-hash-table-length))
(define (s7-initial-string-port-length) (*s7* 'initial-string-port-length))
(define (s7-safety) (*s7* 'safety))
(define (s7-autoloading?) (*s7* 'autoloading?))
(define (s7-max-stack-size) (*s7* 'max-stack-size))
(define (s7-stacktrace-defaults) (copy (*s7* 'stacktrace-defaults)))
(define (s7-gc-stats) (*s7* 'gc-stats))
(define (s7-undefined-identifier-warnings) (*s7* 'undefined-identifier-warnings))
(define (s7-c-types) (*s7* 'c-types))
(define (s7-profile-info) (*s7* 'profile-info))
(define (s7-history-size) (*s7* 'history-size))
(define (s7-default-rationalize-error) (*s7* 'default-rationalize-error))
(define (s7-equivalent-float-epsilon) (*s7* 'equivalent-float-epsilon))
(define (s7-hash-table-float-epsilon) (*s7* 'hash-table-float-epsilon))
(define (s7-bignum-precision) (*s7* 'bignum-precision))
;(define (s7-float-format-precision) (*s7* 'float-format-precision))
(define (s7-default-random-state) (*s7* 'default-random-state))
(define (s7-cpu-time) (*s7* 'cpu-time))

(define (s7-pair-filename x) (string? (pair-filename x)))
(define (s7-pair-line-number x) (integer? (pair-line-number x)))
(define (s7-port-filename x) (string? (port-filename x)))

(define-macro (_mac_ x) `(+ ,x 1))
(define-macro* (_mac*_ (x 1)) `(+ ,x 1))
(define-macro* (_mac1*_ (x 1) :allow-other-keys) `(+ ,x 1))
(define-bacro (_bac_ x) `(+ ,x 1))
(define-bacro* (_bac*_ (x 1)) `(+ ,x 1))
(define (_fnc_ x) (+ x 1))
(define* (_fnc*_ (x 1)) (+ x 1))
(define* (_fnc1*_ (x 1) :allow-other-keys) (+ x 1))
(define (_fnc1_ x) (apply + (list x 1)))
(define (_fnc2_ x) (- x 1))
(define (_fnc3_ x) (* x 2.0))
(define (_fnc4_ x) (/ x))
(define (_fnc5_ x) (not (pair? x)))
;(define (_fnc6_ x) (unless (let? x) (let-temporarily (((*s7* 'safety) 1)) (fill! x #\a))))
;;; (define (_fnc7_ x) (let-temporarily (((*s7* 'safety) 1)) (reverse! x)))
(define (_fnc8_ x) (let-temporarily ((x (+ x 1))) (values x x)))
(define (_fnc9_ arg) (map values arg))

(define (fib n)
  (if (< n 2)
      n
      (+ (fib (- n 1))
         (fib (- n 2)))))

(define (fibr n)
  (if (>= n 2)
      (+ (fibr (- n 1))
         (fibr (- n 2)))
      n))

(define (fibf n)
  (if (< n 2.0)
      n
      (+ (fibf (- n 1.0))
         (fibf (- n 2.0)))))


(define (local-random . args)
  (type-of (apply random args)))

(define (local-read-string . args)
  (with-input-from-file "/home/bil/cl/all-lg-results"
    (lambda ()
      (read-string (min 1000 (car args))))))

(define (checked-eval code)
  (and (pair? code)
       (< (length code) 100)
       (null? (cyclic-sequences code))
       (eval code)))

(define (local-varlet . args)
  (let ((e (car args)))
    (when (and (let? e)
	       (not (eq? e (rootlet)))
	       (not (defined? 'error-type e #t)))
      (apply varlet e (cdr args)))))

(define (local-let-set! . args)
  (let ((e (car args)))
    (when (and (let? e)
	       (not (eq? e (rootlet)))
	       (not (defined? 'error-type e #t)))
      (apply let-set! e (cdr args)))))

(define (checked-hash-table . args)
  (let ((_h_ (make-hash-table (*s7* 'default-hash-table-length) equivalent?)))
    (do ((key/value args (cddr key/value)))
	((null? key/value) _h_)
      (if (not (pair? (cdr key/value)))
	  (error 'wrong-number-of-args "no value")
	  (set! (_h_ (car key/value)) (cadr key/value))))))

(define (checked-stacktrace . args)
  (string? (apply stacktrace args)))
(define (checked-random . args)
  (number? (apply random args)))
(define (checked-random-state . args)
  (random-state? (apply random-state args)))
(define (checked-random-state->list . args)
  (list? (apply random-state->list args)))
(define (checked-make-string . args)
  (let-temporarily ((*s7* max-string-length 12))
    (string? (apply make-string args))))
(define (checked-current-input-port . args)
  (input-port? (apply current-input-port args)))
(define (checked-current-error-port . args)
  (input-port? (apply current-error-port args)))
(define (checked-funclet . args)
  (let? (apply funclet . args)))
(define (checked-hash-code . args)
  (integer? (apply hash-code args)))
(define (checked-*function* . args)
  (procedure? (apply *function* args)))

(define *read-file-name* "s7test.scm")
;(define *read-file-name* "libdl.scm")


(define (checked-read-char . args) (with-input-from-string "0123" (lambda () (apply read-char args))))
(define (checked-read-byte . args) (with-input-from-string "0123" (lambda () (apply read-byte args))))
(define (checked-read-line . args) (with-input-from-file *read-file-name* (lambda () (apply read-line args))))
(define (checked-read-string . args) (with-input-from-file *read-file-name* (lambda () (apply read-string args))))
(define (checked-read . args) (with-input-from-file "dsp.scm" (lambda () (apply read args))))

(define (checked-reverse! . args) (reverse! (copy (car args))))
(define (checked-port-line-number . args) (apply port-line-number args) 0)
(define (checked-procedure-source . args) (copy (procedure-source (car args)) :readable))

(load "s7test-block.so" (sublet (curlet) (cons 'init_func 'block_init)))

(define-expansion (t725-comment . strs) (values)) ; this must be at the top-level, "comment" used as local var in lint.scm

(define-expansion (_dw_ . args)
  `(dynamic-wind #f (lambda () ,@args) #f))

(define-expansion (_dw_out_ . args)
  `(let ((_port_ #f)
	 (_old_port_ #f))
     (dynamic-wind
	 (lambda ()
	   (set! _old_port_ (current-output-port))
	   (set! _port_ (open-output-string))
	   (set! (current-output-port) _port_))
	 (lambda ()
	   ,@args
	   (get-output-string _port_ #t))
	 (lambda ()
	   (close-output-port _port_)
	   (set! (current-output-port) _old_port_)))))

(define-expansion (_cw_ . args)
  `(call-with-exit (lambda (_x_) (_x_ ,@args))))

;;(define-expansion (_cc_ . args)
;;  `(call/cc (lambda (_x_) (_x_ ,@args))))

(define-expansion (_ct1_ . args)
  `(catch #t (lambda () (call-with-exit (lambda (goto) (values ,@args)))) (lambda args 'error)))

(define-expansion (_ct2_ . args)
  `(catch #t (lambda () (call-with-exit (lambda (goto) (goto ,@args)))) (lambda args 'error)))

(define-expansion (_ft1_ . args)
  `(let ((_f_ (lambda () ,@args))) (_f_) (_f_)))

(define-expansion (_ft2_ . args)
  `(let () (define (_f_) ,@args) (define (g) (_f_)) (g) (g)))

(define (_rf11_ i x) (if (> i 0) (_rf11_ (- i 1) x) (x)))
(define-expansion (_rf1_ . args)
  `(let ((y 0)) (_rf11_ 1 (lambda () ,@args))))

(define-expansion (_rf3_ . args)
  `(let ((y 0)) (_rf11_ 1 (lambda () (begin ,@args)))))

(define (_rf22_ i x) (if (> i 0) (_rf22_ (- i 1) x) (x i)))
(define-expansion (_rf2_ . args)
  `(let () (_rf22_ 1 (lambda (y) (begin ,@args)))))

(define-expansion (_do1_ . args)
  `(with-output-to-string
     (lambda ()
       (do ((i 0 (+ i 1)))
	   ((= i 1))
	 (with-immutable (i)
	   ,@(map (lambda (x)
		    (list 'values x))
		  args))))))

(define-expansion (_do2_ . args)
  `(with-output-to-string
     (lambda ()
       (with-immutable (i)
         ,@(map (lambda (x)
		  (list 'values x))
		args)))))

(define-expansion (_do4_ . args)
  `(do ((__var__ #f)
	(_i_ 0 (+ _i_ 1)))
       ((= _i_ 1) __var__)
     (set! __var__ ,@args)))

(define-expansion (_do5_ . args)
  `(let ((__var__ #f))
     (let doer ((_i_ 0))
       (if (= _i_ 1)
	   __var__
	   (begin
	     (set! __var__ ,@args)
	     (doer (+ _i_ 1)))))))

#|
(define-expansion (_do3_ . args)
  `(let ((exiter (vector #f))) (do ,(car args) ((vector-ref exiter 0) 1) ,@(cdr args) (vector-set! exiter 0 #t))))
|#

(define-expansion (_cop1_ . args)
  `(let ((x (begin ,@args)))
     x))

(define-expansion (_cop2_ . args)
  `(let ((x (begin ,@args)))
     (copy x)))

(define-expansion (_rd3_ . args)
  `(let ((port #f))
     (dynamic-wind
	 (lambda ()
	   (set! port (open-input-string (format #f "~W" (car (list ,@args))))))
	 (lambda ()
	   (read port))
	 (lambda ()
	   (close-input-port port)))))

(define-expansion (_rd4_ . args)
  `(with-input-from-string
       (object->string (car (list ,@args)) :readable) ; defaults to ~S
     read))

(define-expansion (_rd5_ . args)
  `(let ((port #f))
     (dynamic-wind
	 (lambda ()
	   (set! port (open-input-string (format #f "~S" (car (list ,@args))))))
	 (lambda ()
	   (read-line port))
	 (lambda ()
	   (close-input-port port)))))

(define-expansion (_rd6_ . args)
  `(with-input-from-string
       (object->string (car (list ,@args)))
     read-line))

(define-expansion (_wr3_ . args)
  `(format #f "~W" (car (list ,@args))))

(define-expansion (_wr4_ . args)
  `(object->string (car (list ,@args)) :readable))

(define-expansion (_let1_ . args)
  `(let-temporarily ((x 1)) (call-with-exit (lambda (go) (go ,@args)))))

(define-expansion (_let2_ . args)
  `(call-with-exit (lambda (go) (let-temporarily ((x 1)) (go ,@args)))))

(define-expansion (_iter_ . args)
  `(let ((erg (list-values ,@args)))
     (let ((iter (if (iterator? erg) erg (make-iterator erg)))
	   (result ()))
       (do ((x (iter) (iter)))
	   ((iterator-at-end? iter) (reverse result))
	 (set! result (cons x result))))))

(define-expansion (_map_ . args)
  `(map values (list ,@args)))

(define-expansion (_cat1_ . args)
  `(catch #t
     (lambda ()
       (catch 'not-oops
	 (lambda ()
	   (throw 'oops ,@args))
	 (lambda (t i)
	   'error)))
     (lambda (t i)
       'error)))

(define-expansion (_cat2_ . args)
  `(catch #t
     (lambda ()
       (catch 'not-oops
	 (lambda ()
	   (error 'oops ,@args))
	 (lambda (t i)
	   'error)))
     (lambda (t i)
       'error)))

(define-constant ims (immutable! (string #\a #\b #\c)))
(define-constant imbv (immutable! (byte-vector 0 1 2)))
(define-constant imbv2 (immutable! #u2d((1 2 3) (4 5 6))))
(define-constant imbv3 (immutable! #u3d(((1 2 3) (1 2 4)) ((1 2 5) (1 2 6)) ((1 2 7) (1 2 8)))))
(define-constant imv (immutable! (vector 0 1 2)))
(define-constant imv2 (immutable! #2d((1 2 3) (4 5 6))))
(define-constant imv3 (immutable! #3d(((1 2 3) (1 2 4)) ((1 2 5) (1 2 6)) ((1 2 7) (1 2 8)))))
(define-constant imiv (immutable! (int-vector 0 1 2)))
(define-constant imiv2 (immutable! #i2d((1 2 3) (4 5 6))))
(define-constant imiv3 (immutable! #i3d(((1 2 3) (1 2 4)) ((1 2 5) (1 2 6)) ((1 2 7) (1 2 8)))))
(define-constant imfv (immutable! (float-vector 0 1 2)))
(define-constant cmfv (immutable! (complex-vector 0+i 1+i 2+2i)))
(define-constant imfv2 (immutable! #r2d((1 2 3) (4 5 6))))
(define-constant imfv3 (immutable! #r3d(((1 2 3) (1 2 4)) ((1 2 5) (1 2 6)) ((1 2 7) (1 2 8)))))
(define-constant imi (immutable! (let ((a 3) (b 2)) (immutable! 'a) (immutable! 'b) (curlet))))
(define-constant ilt (immutable! (openlet (inlet 'let-ref-fallback (lambda (e sym) #<undefined>)))))

(define-constant imh (immutable! (let ((H (make-hash-table 8 #f (cons symbol? integer?)))) (set! (H 'a) 1) (set! (H 'b) 2) H)))
(define-constant imp (immutable! (cons 0 (immutable! (cons 1 (immutable! (cons 2 ())))))))
(define-constant imb (immutable! (block 0.0 1.0 2.0)))
(when with-mock-data
  (define-constant imfi (immutable! (mock-port (open-input-string "asdf"))))
  (define-constant imfo (immutable! (mock-port (open-output-string))))
  (with-let imfo (set! (setter 'value) (lambda (obj field val) (error 'out-of-range "can't set imfo value"))))
  (define-constant imr (immutable! (mock-random-state 123456))))

(define-constant bigi0 (bignum 0))
(define-constant bigi1 (bignum 1))
(define-constant bigi2 (bignum 123))
(define-constant bigf2 (bignum 123.0))
(define-constant bigrat (bignum 1/2))
(define-constant bigflt (bignum 1.5))
(define-constant bigcmp (bignum 1+2i))

(define-constant vvv (let ((v (make-vector '(2 2)))) (set! (v 0 0) "asd") (set! (v 0 1) #r(4 5 6)) (set! (v 1 0) '(1 2 3)) (set! (v 1 1) 32) v))
(define-constant vvvi (let ((v (make-vector '(2 2)))) (set! (v 0 0) "asd") (set! (v 0 1) #r(4 5 6)) (set! (v 1 0) '(1 2 3)) (set! (v 1 1) 32) (immutable! v)))
(define-constant vvvf (immutable! (vector abs log sin)))

(define-constant big-let (let ((e (inlet)))
		  (let-temporarily (((*s7* 'print-length) 80))
		    (do ((i 0 (+ i 1)))
			((= i 100))
		      (varlet e (symbol "abc" (number->string i)) i)))
		  (immutable! e)))
(define-constant big-hash (let ((e (hash-table)))
		   (let-temporarily (((*s7* 'print-length) 80))
		     (do ((i 0 (+ i 1)))
			 ((= i 100))
		       (hash-table-set! e (symbol "abc" (number->string i)) i)))
		   (immutable! e)))

(define-constant patchwork (let ((<L1> (immutable! (list 1))))
			     (set-cdr! <L1> (cons 2 (immutable! (cons 3 ()))))
			     (set-cdr! (list-tail <L1> 2) (list 4))
			     (set-cdr! (list-tail <L1> 3) <L1>)
					;(display (object->string <L1> :readable)) (newline))
			     <L1>))

(define-constant a1 (immutable! (let ((H (make-hash-table 8 #f (cons real? integer?)))) (set! (H +nan.0) 1) H)))
(define-constant a2 (immutable! (inlet :a (hash-table 'b 1))))
(define-constant a3 (openlet (immutable! (inlet :a 1))))
(define-constant a4 (subvector #i2d((1 2) (3 4))))            ; #i(1 2 3 4)
(define-constant a5 (subvector #i2d((1 2) (3 4)) 0 4 '(4)))   ; #i(1 2 3 4)
(define-constant a6 (subvector #i2d((1 2) (3 4)) 1 3 '(2 1))) ; #i2d((2) (3))

(define int-var 1)
(define float-var 1.0)
(define ratio-var 1/2)
(define complex-var 1+i)

(define-constant x1 12345)
(define-constant x2 32.123)
(define-constant x3 2/31)
(define-constant x4 32.0+2.0i)
(define-constant x5 +nan.0)
(define-constant x6 +inf.0)
(define-constant x7 #\a)
(define-constant x8 :hi)
(define-constant x9 'hi)

(define-constant gb1 'gb2)
(define-constant gb2 'gb3)
(define-constant gb3 '(+ 1 2))

(define-constant typed-hash (make-hash-table 8 eq? (cons symbol? integer?)))
(define-constant typed-vector (make-vector 8 'a symbol?))
(define-constant typed-let1 (immutable! (let ((a 1)) (set! (setter 'a) integer?) (curlet))))
(define-constant constant-let (immutable! (let () (define-constant a 1) (curlet))))

(define-constant bight (let* ((size 10) ; was 1000 for a long time
			      (ht (make-hash-table size)))
			 (do ((i 0 (+ i 1)))
			     ((= i size))
			   (hash-table-set! ht (symbol (format #f "a~D" i)) i))
			 (immutable! ht)))

(define-constant fvset float-vector-set!)
(define-constant cvset complex-vector-set!)
(define-constant htset hash-table-set!)

(set! (hook-functions *unbound-variable-hook*) ())
(define last-error-type #f)
(define old-definee #f)
(define-constant L0 (immutable! (let ((a 1)) (immutable! 'a) (curlet))))

(define (tp val) ; [omits trailing "] ... if val long and already a string -- memory-usage needs 2035 at least
  (let ((str (object->string val)))
    (if (< (length str) 4096)
	str
	(string-append (substring str 0 4092) "...\""))))

(define (cons-r a b n) (if (= 0 n) (list a b) (cons (cons-r (+ a 1) (+ b 1) (- n 1)) (cons-r (- a 1) (- b 1) (- n 1)))))
(define (list-r a b n) (if (= 0 n) (list a b) (list (list-r (+ a 1) (+ b 1) (- n 1)) (list-r (- a 1) (- b 1) (- n 1)))))

(define with-bignums (provided? 'bignums))
(define (bool/int? x) (or (boolean? x) (integer? x)))

(set! (hook-functions *read-error-hook*) ())

(define-macro (with-immutable objs . body)
  `(let-temporarily (,@(map (lambda (obj)
			      `((setter ',obj) (lambda (s v)
						 (error 'immutable-object-error
							"in with-immutable, can't set! ~A"
							',obj))))
			    objs))
     ,@body))

(immutable! 'cosh)

(when (not (defined? 'loading-t718))
(let ((functions (vector 'not '= '+ 'cdr 'real? 'rational? 'number? '> '- 'integer? 'apply 'subvector? 'subvector-position 'subvector-vector
			  'abs '* 'null? 'imag-part '/ 'vector-set! 'equal? 'magnitude 'real-part 'pair? 'max 'nan? 'string->number 'list
			  'negative? 'cons 'string-set! 'list-ref 'eqv? 'positive? '>= 'expt 'number->string 'zero? 'floor 'denominator 'integer->char
			  'string? 'min '<= 'char->integer 'cos 'rationalize 'cadr 'sin 'char=?
			  'list-set! 'defined? 'memq 'string-ref 'log
			  'for-each 'map 'nan 'nan-payload
			  'round 'ceiling 'truncate 'string=? 'atan 'eof-object? 'numerator 'char? 'cosh 'member 'vector
			  'even? 'string-append 'char-upcase 'sqrt 'my-make-string
			  'char-alphabetic? 'odd? 'call-with-exit 'tanh 'copy 'sinh 'make-vector
			  'string 'char-ci=? 'caddr 'tan 'reverse 'cddr 'append 'vector? 'list? 'exp 'acos 'asin 'symbol? 'char-numeric? 'string-ci=?
			  'char-downcase 'acosh 'vector-length 'asinh 'format
			  'make-list 'goto?
			  ;'sort! ; qsort_r has a memory leak if error raised by comparison function
			  'atanh 'modulo 'make-polar 'gcd 'angle 'remainder 'quotient 'lcm
			  'char-whitespace? 'assoc 'procedure? 'char<?
			  'inexact->exact 'vector->list 'boolean? 'undefined? 'unspecified?
			  'caar (if with-bignums '+ 'ash) ; overflow memory else?
			  'list-tail 'symbol->string 'string->symbol 'exact->inexact
			  'object->string 'char>? 'symbol->value
			  'cadar 'integer-decode-float 'string-copy 'cdddr 'logand 'cadddr
			  'with-input-from-string 'substring 'substring-uncopied 'string->list 'char-upper-case?
			  'hash-table-set! 'cddddr 'string<? 'dynamic-wind 'call-with-input-file 'error
			  'lognot 'cdar 'char-ci>=? 'string>=?
			  'dilambda 'string-ci<? 'char<=? 'logior 'char-ci<=? 'assv
			  'string>? 'char-ci>? 'char-lower-case? 'string-ci>=? 'string-ci>? 'string<=? 'caadr 'char-ci<?
			  ;'reverse! ; quasiquoted lists are problematic
			  'string-ci<=? 'cadadr 'cdadr 'provided? 'caaaar 'caaddr 'caddar 'cdaaar 'cdaadr 'cdaddr 'cddar
			  ;'fill! ; see _fnc6_
			  'hash-table-ref 'list->vector 'caaadr 'caaar 'caadar 'cadaar 'cdadar 'cdddar 'string-fill! 'cdaar 'cddaar 'cddadr
			  'symbol->keyword ; 'string->keyword 'symbol ; size grows
			  'keyword->symbol 'keyword?
			  'logxor  'memv 'char-ready?
			  'exact? 'integer-length ;'port-filename ; -- (load (port-filename)) -> infinite loop
			  'char>=?
			  'string-length 'list->string 'inexact?
			  'with-input-from-file 'type-of
			  'vector-fill! 'vector-typer 'hash-table-key-typer 'hash-table-value-typer
			  'peek-char
			  'make-hash-table 'make-weak-hash-table 'weak-hash-table?
			  ;'hash-code ; too many uninteresting diffs
			  'macro?
			  'quasiquote
			  'immutable? 'char-position 'string-position
			  'infinite?
			  'vector-dimensions 'vector-dimension 'vector-rank 'get-output-string
			  'sublet 'inlet

			  'call-with-input-string 'documentation
			  'continuation? 'hash-table? 'port-closed? 'port-position 'port-file 'port-string
			  'output-port? 'input-port?
			  ;'provide
			  'call-with-output-string
			  'checked-hash-table 'checked-stacktrace 'checked-random 'checked-random-state 'checked-random-state->list 'checked-make-string
			  'checked-current-input-port 'checked-current-error-port 'checked-funclet 'checked-hash-code
			  'with-output-to-string
			  'dilambda?
			  'hook-functions
			  'c-pointer->list 'c-pointer-info 'c-pointer-type 'c-pointer-weak1 'c-pointer-weak2
			  ;'show-profile

			  ;'make-hook ; can get #=1(1 . #1#) as arglist!
			  'let 'let* 'letrec 'letrec*
			  ;'lambda 'lambda*  ; these cause built-ins to become locals if with-method=#f?
			  ;'macro 'macro* 'bacro 'bacro* ; -- same as lambda above
			  ;'define* 'define-macro 'define-macro* 'define-bacro 'define-bacro* 'define-constant
			  'define
			  ;'multiple-value-bind ; (multiple-value-bind (if) ...) gets all kinds of trouble
			  'call-with-values
			  'object->let

			  'open-input-string 'open-output-string
			  'open-input-file
			  'open-input-function 'open-output-function
			  'newline
			  ;'random-state ; pointless diffs
			  'case*
			  ;'do
			  ;'cond
			  'case
			  'or 'and 'when 'unless 'if 'begin
			  'with-baffle 'let-temporarily 'with-let
			  'byte-vector-set! 'my-make-byte-vector
			  'write-char 'write-byte 'write-string
			  (reader-cond (with-continuations 'call/cc))
			  'file-mtime
			  'write 'display
			  (reader-cond ((not with-mock-data) 'outlet))
			  'directory->list
			  'set! ; this can clobber stuff making recreating a bug tricky
			  'set-car!
			  ;'call-with-output-file 'with-output-to-file
			  'read-char 'read-byte 'read-line 'read-string 'read ; stdin=>hangs (but now it is #f)
			  'checked-read-char 'checked-read-line 'checked-read-string 'checked-read-byte ;'checked-read
			  'checked-reverse! 'checked-port-line-number 'checked-*function*
			  'close-input-port
			  ;'current-input-port ;-- too many (read...)
			  ;'set-current-input-port ; -- collides with rd8 etc
                          ;'set-cdr! ; can create cyclic code and numerous other problems
                          ;'unlet ;-- spurious diffs
                          'port-line-number ;-- too many spurious diffs
			  ;'load  ; -- (load (port-filename)) ;'current-error-port ;-- spurious output ; (load <any string>) etc
			  ;'close-output-port
			  'hash-table ; -- handled as equivalent via checked-hash-table
			  'current-output-port
			  'cutlet
			  ;'set-current-error-port ;-- too many bogus eq? complaints (it returns previous port)
			  ;'curlet ; (length (curlet)) too many times
 			  ;'open-output-file -- horrible arbitrary undeletable files
			  ;'delete-file 'set-current-output-port
			  'autoload
			  ;'varlet ;-- error exits, chaos in rootlet (see local-varlet)
			  ;'eval ; -- can't use if signature (circular program) or (make-list (max-list-len))
			  'checked-eval
			  ;'immutable!
			  'checked-procedure-source 'procedure-arglist
			  ;'owlet ;too many uninteresting diffs
			  ;'gc  ; slower? and can be trouble if called within an expression
			  ;'reader-cond ;-- cond test clause can involve unbound vars: (null? i) for example, and the bugs of eval-time reader-cond are too annoying
			  ;'funclet ; '*function* ; tons of output in both cases, not interesting
			  ;'random
			  ;;; 'quote
			  '*error-hook* ;'*autoload-hook*
			  ;'cond-expand ; (cond-expand (reader-cond...)) too many times
			  ;'random-state->list
                          ;'pair-line-number 'pair-filename ; -- too many uninteresting diffs
			  ;'s7-pair-line-number 's7-pair-filename 's7-port-filename ; these depend on optimization state (overwriting location info)
			  'let-set!
			  ;'coverlet ;-- blocks block's equivalent?
                          'help ;-- snd goes crazy
			  'macroexpand ;-- uninteresting objstr stuff
			  'signature ; -- circular lists cause infinite loops with (e.g.) for-each??
			  'eval-string
			  'tree-member 'tree-memq 'tree-set-memq 'tree-count 'tree-leaves
			  'tree-cyclic?
                          'require
			  'else '_mac_ '_mac*_ '_bac_ '_bac*_ '_mac1*_ '_fnc1*_
			  '_fnc_ '_fnc*_ '_fnc1_ '_fnc2_ '_fnc3_ '_fnc4_ '_fnc5_ '_fnc8_ '_fnc9_   ;'_fnc6_
			  '=>

			  'constant?
			  '*unbound-variable-hook* '*load-hook* '*rootlet-redefinition-hook* '*missing-close-paren-hook*
			  '*read-error-hook*
			  '*after-gc-hook*
			  '*autoload*
			  'sequence? 'directory? 'hash-table-entries
			  'arity 'logbit?
			  'random-state? 'throw 'float-vector-set! 'make-iterator 'complex 'complex-vector-set!
			  'let-ref 'int-vector 'aritable? 'gensym? 'syntax? 'iterator-at-end? 'let? 'gensym
			  'subvector 'float-vector 'iterator-sequence 'getenv 'float-vector-ref 'complex-vector 'complex-vector-ref
			  'cyclic-sequences ;'let->list ; with let extensions this complains too much
			  ;'checked-linter

			  'setter 'int-vector?
			  'int-vector-set! 'c-object? 'c-object-type 'proper-list?
			  'symbol->dynamic-value
			  'vector-append
			  'flush-output-port 'c-pointer 'make-float-vector 'make-complex-vector
			  'iterate 'float-vector? 'complex-vector?
			  'apply-values
			  'values
			  'byte-vector-ref 'file-exists? 'make-int-vector 'string-downcase 'string-upcase
			  'byte-vector 'equivalent? 'make-byte-vector
			  'c-pointer? 'int-vector-ref
			  'float?
			  'list-values 'byte-vector? 'openlet? 'iterator?
			  (reader-cond ((not with-mock-data) 'openlet))
			  'string->byte-vector 'byte-vector->string

			  'checked-pp
			  's7-undefined-identifier-warnings
			  's7-profile-info
			  ;'s7-autoloading?
			  's7-safety
			  's7-c-types
			  's7-initial-string-port-length 's7-history-size
			  's7-default-rationalize-error 's7-equivalent-float-epsilon
			  's7-hash-table-float-epsilon 's7-bignum-precision
			  ;'s7-float-format-precision
			  's7-stacktrace-defaults

			  'block 'make-block 'block? 'block-ref 'block-set!
			  'blocks 'unsafe-blocks 'blocks1 'unsafe-blocks1 'blocks3 'unsafe-blocks3 'blocks4 'unsafe-blocks4 'blocks5
			  'values2 'unsafe-values2
			  'block-reverse! 'subblock 'block-append 'block-let
			  ;'simple-block? 'make-simple-block ;'make-c-tag ; -- uninteresting diffs
			  'make-cycle
			  ;'make-c-tag1 ; from s7test.scm, as above

			  'fvref 'cvref 'ivref 'bvref 'vref 'fvset 'ivset 'bvset 'vset 'adder 'cvset

			  'undefined-function
			  'subsequence
			  'empty? 'indexable?
			  ;'adjoin 'cdr-assoc
			  'n-values
			  'progv ;'value->symbol ;-- correctly different values sometimes, progv localizes
			  'string-case 'concatenate
			  '2^n? 'lognor 'ldb 'clamp
			  ;'log-n-of ; uninteresting complaints
			  ;'sandbox ;-- slow and talkative
			  'circular-list? ;;'hash-table->alist -- hash map order problem
			  'weak-hash-table 'byte? 'the 'lognand 'logeqv
			  'local-random
			  'local-read-string 'local-varlet 'local-let-set!
			  ;'pp-checked
			  'kar '_dilambda_ '_vals_ '_vals1_ '_vals2_
                          '_vals3_ '_vals4_ '_vals5_ '_vals6_ '_vals3s_ '_vals4s_ '_vals5s_ '_vals6s_
                          '_svals3_ '_svals4_ '_svals5_ '_svals6_ '_svals3s_ '_svals4s_ '_svals5s_ '_svals6s_
			  'sym1 'sym2 'sym3 'sym4 'sym5 'sym6 'msym1 'msym2 'msym3  'msym5 ;'msym6 ;'msym4 'msym5 'msym6 'msym8
			  'fop1 'fop2 'fop3 'tff 'fop4 'fop5 'fop6 'tf7 'tf8 'tf9 'tf10 'tf13 'tf14
			  'tf15 'tf16 'tf17 'tf18 'tf19 'tf20 'tf21 'tf22 'tf23 'tf24 'tf25 'tf26 'tf27 'fop29
			  'tf30 'tf31 'tf32 'tf33 'tf34 'f40 'f41
			  'match?
			  'catch 'length 'eq? 'car '< 'assq 'complex? 'vector-ref
			  'ifa 'ifb ; see fix-op below

			  '_asdf_
			  'ims 'imbv 'imv 'imiv 'imfv 'imi 'imp 'imh 'ilt 'cmfv
			  'imv2 'imv3 'imfv2 'imfv3 'imiv2 'imiv3 'imbv2 'imbv3
			  'vvv 'vvvi 'vvvf 'typed-hash 'typed-vector 'typed-let 'constant-let 'bight
			  'a1 'a2 'a3 'a4 'a5 'a6
			  'gb1 'gb2 'gb3
			  'cf00 'c-function-with-values 'c-macro-with-values 'safe-c-function-with-2-values

			  'bignum 'symbol 'count-if 
			  ;'pretty-print
			  'funclet? 'bignum? 'copy-tree
			  ;'dynamic-unwind ; many swaps that are probably confused
                          ;'function-open-output 'function-open-input 'function-get-output 'function-close-output ;see s7test, not set up for t725

			  'symbol-initial-value
			  ;'swap!
			  'continuer
			  'recall1 'recall2
			  '_asdf_
			  ))

      (args (vector "-123" "1234" "-3/4" "-1" "1/2" "1+i" "1-i" "0+i" "0-i" "(expt 2 32)" "4294967297" "1001" "10001"
		    "3441313796169221281/1720656898084610641" "1855077841/1311738121" "4478554083/3166815962" "20057446674355970889/10028723337177985444"
		    "(cosh 128)" "(cosh (bignum 128.0))" "(bignum -1/2)" "123456789.123456789" "(bignum 1234)" "(bignum 1234.1234)" "(bignum 1+i)"
		    "(bignum +inf.0)" "(bignum +nan.0)" "(bignum -inf.0)" "(bignum 0+i)" "(bignum 0.0)" "(bignum 0-i)"
		    "(expt 2 -32)" "1/2+1/3i"
		    "=>"

		    (reader-cond
		     (with-bignums
		      "85070591730234615856620279821087277056" "11538170533094188269009/1311738121"
		      "85070591730234615856620279821087277056.11538170533094188269009"
		      "85070591730234615856620279821087277056.0+11538170533094188269009.0i"))

		    "\"ho\"" ":ho" "ho:" "'ho" "(list 1)" "(list 1 2)" "(cons 1 2)" "()" "(list (list 1 2))" "(list (list 1))" "(list ())"
		    "#f" "#t" "()" "#()" "\"\"" ; ":write" -- not this because sr2 calls write and this can be an arg to sublet redefining write
		    "'(1 2 . 3)" "'(1 . 2)" "'(1 2 3 . 4)"
		    ":readable" ":rest" ":allow-other-keys" ":display" ":write" ":if" "':abs" ":a" "a:" ":frequency" ":scaler" ; for blocks5 s7test.scm
		    "1/0+i" "0+0/0i" "0+1/0i" "1+0/0i" "0/0+0/0i" "0/0+i" "+nan.0-3i" "+inf.0-nan.0i"
		    "cons" "\"ra\"" "''2" "'a" "_!asdf!_" "let-ref-fallback"

		    "#\\a" "#\\A" "#\\x" ;"\"str1\"" "\"STR1\"" "#\\0" "0+." ".0-"
		    "(make-hook)" "(make-hook '__x__)"
		    "1+i" "0+i" "(ash 1 43)"  "(fib 8)" "(fibr 8)" "(fibf 8.0)"
		    "(integer->char 255)" "(string (integer->char 255))" "(string #\\null)" "(byte-vector 0)"
		    "pi" "+nan.0" "+nan.123" "+inf.0" "-inf.0" "-nan.0" "1.0e-309"
		    "(list)" "(string)" "#r()" "#u()" "(vector)" "#i()" "(make-iterator #(10 20))" "#i(1)"
		    "0" "1" "4" "1.0" "-1.0" "1.0+123.0i" "3/4" "(make-vector 3)" "(make-string 3 #\\space)" "(make-vector '(2 3))"
		    "'((111 2222) (3 4))" "'((1 (2)) (((3) 4)))" "(byte-vector 255)" "(make-byte-vector '(2 3) 0)"
		    "#(123 223)" "(vector 1 '(3))" "(let ((x 3)) (lambda (y) (+ x y)))" "abs" "(lambda sym-args sym-args)" "#u(0 1)"
		    "'((1) (vector 1))" "(abs x)" "(symbol? x)" "(cons x x)" "(cons i i)" "(vector i x)" "(vector x i)"
		    "(dilambda (lambda () 1) (lambda (a) a))" "quasiquote" "macroexpand" "(lambda* ((a 1) (b 2)) (+ a b))"
		    "(dilambda (lambda args args) (lambda args args))" "(dilambda (lambda* (a b) a) (lambda* (a b c) c))"
		    "((lambda (a) (+ a 1)) 2)" "((lambda* ((a 1)) (+ a 1)) 1)" "(lambda (a) (values a (+ a 1)))" "((lambda (a) (values a (+ a 1))) 2)"
		    "(lambda a (copy a))" "(lambda (a . b) (cons a b))" "(lambda* (a . b) (cons a b))" "(lambda (a b . c) (list a b c))"
		    "(define-macro (_m1_ a) `(+ ,a 1))" "(define-bacro (_b1_ a) `(* ,a 2))"
		    "(macro (x) (let ((g (gensym))) (let ((,g ,x)) `(values g g))))"
		    "((dilambda (lambda () 3) (lambda (x) x)))"
		    "(macro (a) `(+ ,a 1))" "(bacro (a) `(* ,a 2))" "(macro* (a (b 1)) `(+ ,a ,b))" "(bacro* (a (b 2)) `(* ,a ,b))"
		    "(macro a `(copy ,a))" "(macro (a . b) `(cons ,a ,b))" "(macro* (a . b) `(cons ,a ,b))" "(macro (a b . c) `(list ,a ,b ,c))"
		    "(string #\\c #\\null #\\b)" "#2d((100 200) (3 4))" "#r(0 1)" "#i2d((101 201) (3 4))" "#r2d((.1 .2) (.3 .4))" "#i1d(15 25)"
		    "(values 1 2)" "(values)" "(values #\\c 3 1.2)" "(values \"ho\")" "(values 1 2 3 4 5 6 7 8 9 10)" "(values (define b1 3))"
		    "(apply values (make-list 128 1/2))"
		    "(values 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65)"
		    "(values (values 1 2 3))"
		    "0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24"
		    "(log 1.0) (log 2.0)"
		    "(log 1.0) (log 2.0) (log 3.0)"
		    "(log 1.0) (log 2.0) (log 3.0) (log 4.0)"
		    "(log 1.0) (log 2.0) (log 3.0) (log 4.0) (log 5.0)"
		    "(log 1.0) (log 2.0) (log 3.0) (log 4.0) (log 5.0) (log 6.0) (log 7.0) (log 8.0) (log 9.0) (log 10.0) (log 11.0) (log 12.0) (log 13.0) (log 14.0) (log 15.0) (log 16.0) (log 17.0) (log 18.0) (log 19.0) (log 20.0) (log 21.0) (log 22.0) (log 23.0) (log 24.0) (log 25.0) (log 26.0) (log 27.0) (log 28.0) (log 29.0) (log 30.0) (log 31.0) (log 32.0) (log 33.0) (log 34.0) (log 35.0) (log 36.0) (log 37.0) (log 38.0) (log 39.0) (log 40.0) (log 41.0) (log 42.0) (log 43.0) (log 44.0) (log 45.0) (log 46.0) (log 47.0) (log 48.0) (log 49.0) (log 50.0) (log 51.0) (log 52.0) (log 53.0) (log 54.0) (log 55.0) (log 56.0) (log 57.0) (log 58.0) (log 59.0) (log 60.0) (log 61.0) (log 62.0) (log 63.0) (log 64.0) (log 65.0) (log 66.0) (log 67.0) (log 68.0) (log 69.0) (log 70.0) (log 71.0) (log 72.0) (log 73.0) (log 74.0) (log 75.0) (log 76.0) (log 77.0) (log 78.0) (log 79.0) (log 80.0) (log 81.0) (log 82.0) (log 83.0) (log 84.0) (log 85.0) (log 86.0) (log 87.0) (log 88.0) (log 89.0) (log 90.0) (log 91.0) (log 92.0) (log 93.0) (log 94.0) (log 95.0) (log 96.0) (log 97.0) (log 98.0) (log 99.0) (log 100.0)"
		    "`(x)" "`(+ x 1)" "`(x 1)" "`((x))" "`((+ x 1))" "`(((+ x 1)))" "`((set! x (+ x 1)) (* x 2))" "`((x 1))" "`(((x 1))) "
		    "`(x . 1)" "`((x . 1))" "`(1)" "`((1))" "`((1) . x)" "'(- 1)"
		    "(+ i 1)" "(pi)"
		    "'(())" "'((()))" ;"(random-state 1234)"
                    "((if (> 3 2) abs log) 1)" "((if (> 3 2) + -) 3 2)"
		    "((if (> 3 2) or and) #t #f)"
		    "float-var" "int-var" "ratio-var" "complex-var"
		    (reader-cond ((provided? 'number-separator) "1,232"))
		    "(eval-string \"(reader-cond ((provided? 'surreals) 123))\")"
		    "(eval-string \"(t725-comment this is a comment)\")"

                    "(apply + (make-list 2 3))" "(let ((a 1) (b 2) (c 3)) (+ a b c))" "(let ((x '(\"asdf\"))) (apply #_format #f x))"
                    "(cons (cons + -) *)" "(list (list quasiquote +) -1)" "(let ((s '(1 2))) (list (car s) (cdr s)))"
                    "(let ((i 3)) (list i (expt 2 i)))" "(more-values)" "(- (+ x x) (* x x))"

		    "(c-pointer 0 'integer?)" "(c-pointer -1)" "(c-pointer 1234 1.0 2.0 3.0)" "(c-pointer (bignum 1) (vector) (vector 1) (vector 2))"
		    "(inlet 'integer? (lambda (f) #f))" "(inlet 'a 1)"
		    "(openlet (inlet 'abs (lambda (x) (if (real? x) (if (< x 0.0) (- x) x) (error 'wrong-type-arg \"not a real\")))))"
		    "(openlet (inlet 'zero? (lambda (x) (if (number? x) (= x 0.0) (error 'wrong-type-arg \"not a number\")))))"
		    "(inlet 'a (inlet 'b 1))" "(if (integer? (with-let ilt (abs -1))) (error 'oops \"oops ilt\"))"
		    "(L0 'a)" "(L0 :a)" "(let-ref L0 (keyword->symbol :a))" "(let-ref L0 :a)" "(L0 ':a)" "(let-ref L0 'a)"
		    "'(15 26 . 36)"
		    ;" . " ; -- read-errors
		    "((i 0 (+ i 1)))" "(= i 2)" "(zero? i)" "((null? i) i)"
		    "(#t ())"
		    "`(+ ,a ,@b)" "`(+ ,a ,b)" "`(+ ,a ,b ,@c)" "`(+ ,a b ,@c ',d)"
		    "_definee_"
		    "(hash-table 'a 1.5)" "(hash-table)" "(hash-table 'a (hash-table 'b 1))"
		    "(weak-hash-table 1.0 'a 2.0 'b 3.0 'c)"
		    "(make-iterator (list 11 22 33))" "(make-iterator (int-vector 1 2 3))" "(make-iterator (string #\\1))" "(make-iterator x)"
		    "(make-iterator (make-vector '(2 3) #f))" "(make-iterator #r())"
		    "(make-iterator (hash-table 'a -1/2 'b 2))"
		    "(make-iterator (weak-hash-table 1.0 'a 2.0 'b 3.0 'c))"
		    "(make-iterator (weak-hash-table \"1\" 1.0 \"2\" 2.0 \"3\" 3.0))"
		    "(make-iterator (weak-hash-table (gensym) 1.0 (symbol \"2\") 2.0 (weak-hash-table 'a 1) 3.0))"
		    "(make-iterator (let ((lst '((a . 1) (b . 2) (c . 2)))
                                          (+iterator+ #t))
                                      (lambda ()
                                        (if (pair? lst)
                                            (let ((res (list (caar lst) (cdar lst))))
                                              (set! lst (cdr lst)) res)
                                            #<eof>))))"
		    (reader-cond
		     (with-continuations
		    "(display (call/cc (lambda (return)
					(let ((val \"line 1~%line 2~%line 3\"))
					  (call-with-input-string val
					    (lambda (p) (return 'oops)))))))"
		    "(display (call-with-exit (lambda (return)
					(let ((val \"line 1~%line 2~%line 3\"))
					  (with-input-from-string val
					    (lambda (p) (return 'oops)))))))"
		    "(display (call/cc (lambda (return)
					  (call-with-output-string
					    (lambda (p) (return 'oops))))))"))

		    "#<eof>" "#<undefined>" "#<unspecified>" "#unknown" "___lst" "#<bignum: 3>"
		    "#<>" "#<label:>" "#<...>" "..." "(cons #_quote call-with-exit)" ; "(#_quote . call-with-exit)"
		    "#_and" "'#_or" "#_abs" "#_+"
		    "#o123" "#b101" "#\\newline" "#\\alarm" "#\\delete" "#_cons" "#x123.123" "#\\x65"
		    "#i(60 0 0 0 0 1 0 0 0 1 1 0 0 1 0 1 0 0 1 1 1 0 1 1 0 1 0 0 0 0 0 0 0 0 0 0 1 1 0 1 0 1 0 0 0 1 0 1 1 0 0 0 1 1 1 1 1 0 0 1 1)"
		    "#r(0.000000 0.303100 0.261228 0.917131 0.691793 -0.677124 0.027342 -0.014801 1.166154 0.416979 0.851167 1.410955 0.139409 -0.306122 1.416862 1.054300 0.792442 0.062922 1.507148 0.118287 1.375215 1.459904 1.620963 0.828106 -0.237368 0.987982 0.753194 0.096604 1.712227 1.239483 0.673351 0.871862 0.125962 0.260000 0.626286 0.147473 0.131774 0.201212 -0.194457 0.538798 0.418147 1.292448 0.871870 0.794549 0.988888 1.131816 -0.166311 0.052304 0.543793 -0.229410 0.113585 0.733683 0.271039 1.008427 1.788452 0.654055 0.106430 0.828086 0.097436 0.376461)"
		    "(let ((x 0.0) (y 1.0)) (do ((.i 0 (#_+ .i 1))) ((#_= .i 2) (set! x (#_+ x y))) (set! x (#_* .i .1))))" ; if = is -, infinite loop
		    "(values 60 0 0 0 0 1 0 0 0 1 1 0 0 1 0 1 0 0 1 1 1 0 1 1 0 1 0 0 0 0 0 0 0 0 0 0 1 1 0 1 0 1 0 0 0 1 0 1 1 0 0 0 1 1 1 1 1 0 0 1 1)"
		    "(values 512 0 0 1 1 0 0 0 0 1 0 0 0 1 0 0 1 0 0 1 1 0 0 1 1 1 0 1 1 1 0 0 1 1 1 0 0 1 1 1 0 1 0 0 0 0 1 1 1 0 0 1 0 0 1 1 0 0 1 0 0 0 1 0 1 1 1 0 1 0 0 1 0 0 1 0 0 0 0 0 1 1 0 0 1 0 1 0 0 0 0 1 0 0 0 1 0 1 1 1 1 1 0 1 1 0 1 1 1 1 0 0 0 0 0 0 1 1 1 0 0 1 0 0 0 0 1 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 1 0 1 0 1 1 0 0 1 1 1 0 0 1 0 1 1 0 0 1 0 1 0 0 1 1 1 0 1 0 0 1 0 0 1 0 0 0 1 0 1 1 0 0 0 1 1 1 0 0 0 0 1 1 1 0 1 0 0 1 1 0 1 0 0 0 0 0 0 1 0 0 0 1 1 0 1 0 1 0 0 0 0 1 1 1 0 0 0 0 0 0 0 1 0 1 1 0 0 1 0 0 0 1 0 1 0 0 1 1 1 0 0 1 0 1 1 1 1 0 1 1 1 1 0 0 1 0 0 1 0 0 1 1 1 1 0 0 1 1 1 1 0 0 0 1 0 0 0 1 1 1 0 0 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 0 0 0 1 0 0 1 0 1 0 1 1 1 1 0 0 1 0 0 1 1 0 1 0 1 1 0 0 0 1 0 1 1 0 0 1 1 1 0 0 1 0 0 1 1 1 1 0 0 1 0 1 1 1 1 1 1 1 0 0 0 1 0 1 1 1 0 1 0 1 1 1 1 0 1 0 1 0 1 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 0 1 0 1 1 0 0 1 1 0 0 0 1 0 0 1 1 0 0 0 0 1 0 0 0 0 1 1 0 0 0 0 1 0 1 0 0 1 0 0 0 0 0 0 0 1 0 0 1 0 1 0 1 1 0 1 1 1 0 0 1 1 1 1 1 0 0 0 0 1 1 0 0 0 0 1 1 1 0 1 0 1 0 0 1 0 0 1 0 0 1 1 1 0 0 0 0 0 1 0 1)"

		    "(call-with-exit (lambda (goto) goto))"
		    "(symbol->string 'x)" "(symbol \"a b\")" "(symbol \"(\\\")\")"
		    "(call-with-exit (lambda (return) (return 'ce)))"
		    "(call-with-exit (lambda (return) (let ((x 1) (y 2)) (return x y))))"
		    (reader-cond
		     (with-continuations
		       "(with-baffle (call/cc (lambda (cc) (cc 1))))"
		       "(call/cc (lambda (return) (return 'oops)))"
		       "(call/cc (lambda (return) (let ((x 1) (y 2)) (return x y))))"))
		    "(let ((x 1)) (dynamic-wind (lambda () (set! x 2)) (lambda () (+ x 1)) (lambda () (set! x 1))))"

		    "(let-temporarily ((x 1)) x)" "(let-temporarily ((x #(1)) (i 0)) i)"
		    "(s7-init-and-free))"

		    "1+1e10i" "1e15-1e15i" ;"0+1e18i" "-1e18"
		    ;"(+ 10 (random 90))" ; number->string so lengths differ
		    "(random 1)" "(random 0)" "(random -1)"
		    ;"(else ())" "(else (f x) B)"
		    "(else)" "'__asdf__" "___asdf___" "(+ 1 ____asdf____)"
		    "else" "x" "i" "j" "(+ x 1)" "(+ 1/2 x)" "(abs x)" "(+ x 1 2+i)" "(* 2 x 3.0 4)" "((x 1234))" "((x 1234) (y 1/2))" "'x" "(x 1)"
		    "_undef_" "(begin |undef1|)" "(setter 'x)" "(setter 'i)"

		    "+signature+" "+documentation+" "+setter+" "+iterator+"
		    "(let ((+documentation+ \"help\")) (lambda (x) x))"
		    "(let ((+iterator+ #t)) (lambda () #<eof>))"
		    "(let ((+signature+ (list 'integer? 'integer?))) (lambda (x) (logand x 1)))"
		    "(let ((x 1)) (let ((+setter+ (lambda (val) (set! x val)))) (lambda () x)))"

		    "__var2__"
		    ; "\"~S~%\"" "\"~A~D~X\"" "\"~{~A~^~}~%\"" "\"~NC~&\"" ; -- creates files by these names?
		    "(call-with-input-file *read-file-name* (lambda (p) p))"
		    "(call-with-output-string (lambda (p) p))"

		    "ims" "imbv" "imv" "imiv" "imfv" "imi" "imp" "imh"
		    "imv2" "imv3" "imfv2" "imfv3" "imiv2" "imiv3" "imbv2" "imbv3"
		    "vvv" "vvvi" "vvvf" "typed-hash" "typed-vector" "typed-let1" "constant-let"
		    "a1" "a2" "a3" "a4" "a5" "a6"
		    "x1" "x2" "x3" "x4" "x5" "x6" "x7" "x8" "x9"

		    "(make-hash-table 8 eq? (cons symbol? integer?))"
		    "(make-hash-table 8 equivalent? (cons symbol? #t))"
		    "(let ((a 1)) (set! (setter 'a) integer?) (curlet))"

		    "bigi0" "bigi1" "bigi2" "bigrat" "bigflt" "bigcmp" "bigf2" "Hk"
		    "(ims 1)" "(imbv 1)" "(imv 1)" "(imb 1)" "(imh 'a)" "(imi 'a)"
		    "V_1" "V_2" "H_1" "H_2" "H_3" "H_4" "H_5" "H_6" "L_6"

		    "(make-iterator (block 1 2 3))"
		    "(vector-dimensions (block))"
		    "(append (block) (block))"
		    "(make-vector 3 (block 0.0) block?)"
		    "(make-hash-table 8 #f (cons symbol? block?))"
		    "(make-block 2)" "(block 1.0 2.0 3.0)" "(block)"
		    "imb"
		    "(provide 'asdf)" "*features*"

		    (reader-cond
		     (with-mock-data
		      "imfi" "imfo" "imr"
		      "(mock-number 0)" "(mock-number 1-i)" "(mock-number 4/3)" "(mock-number 2.0)"
		      "(mock-string #\\h #\\o #\\h #\\o)"
		      "(mock-pair 2 3 4)"
		      "(mock-char #\\b)"
		      "(mock-symbol 'c)"
		      "(mock-vector 1 2 3 4)"
		      "(mock-hash-table 'b 2)" "(mock-hash-table 'b (mock-number 2))"
		      "(mock-c-pointer -1)"
		      ;"(mock-port (open-input-port *read-file-name*))"
		      "(mock-random-state 1234)"))
		    "'value"

		    "(subvector 0 3 (vector 0 1 2 3 4))" "(substring \"0123\" 2)" "(vector (lambda (a . b) a))" "(substring-uncopied \"abcdefg\" 0 2)"
		    "(let-temporarily ((x 1234)) (+ x 1))"
		    "(error 'oops \"an error!\")" "(a_sdf)" "(a_sdf 1)"
		    "(define b2 32)"

		    ;"quote" "'" "(quote)"
		    ;"(quote . 1)" "(when)" "(when . 1)" ; -- inconsistent error checks if code unreachable
		    ;"if" ; causes stack overflow when used as lambda arg name and (()... loop)
		    "begin" "cond" "case" "when" "unless" "letrec" "letrec*" "or" "and" "let-temporarily"
		    "catch" "call-with-exit" "map" "for-each"
		    ;"lambda*" "lambda" ;-- cyclic body etc
		    ;"let" "let*" ;"do" ; infinite loops
		    "set!" "with-let" "values" "let-set!" ;"define" "define*" "define-macro" "define-macro*" "define-bacro" "define-bacro*"

		    "(let ((L (list 1))) (set-cdr! L L) L)"
		    "(let ((L (list 1 2))) (set-cdr! (cdr L) L) L)"
		    "(let ((L (list 1 2 3))) (set-cdr! (cddr L) L) L)"
		    "(let ((<1> (vector #f))) (set! (<1> 0) <1>) <1>)"
		    "(let ((<1> (inlet :a #f))) (set! (<1> :a) <1>) <1>)"
		    "(let ((<1> (hash-table))) (set! (<1> 'a) <1>) <1>)"
		    "(let ((<1> #f) (<2> (vector #f))) (set! <1> (make-iterator <2>)) (set! (<2> 0) <1>) <1>)"
		    "(let ((<1> (list 1 #f))) (set! (<1> 1) (let ((<L> (list #f 3))) (set-car! <L> <1>) <L>)) <1>)"
		    "(let ((cp (list 1))) (set-cdr! cp cp) (list '+ 1 (list 'quote cp)))"
		    "(let ((cp (list 1))) (set-cdr! cp cp) (list 'quote cp))"
		    "(let ((cp (list 1))) (set-cdr! cp cp) (list (list quote cp)))"

		    ;"(let ((lst (list '+ 1))) (set-cdr! (cdr lst) (cdr lst)) (apply lambda () lst ()))"
		    ;"(let ((lst (list '+ 1))) (set-cdr! (cdr lst) (cdr lst)) (apply lambda* () lst ()))"

		    "patchwork"

		    "(gensym \"g_123\")"
		    "(make-list 256 1)" "(make-list 512 '(1))" "big-let" "big-hash"
		    "(make-vector 256 #f)" "(make-byte-vector 256 0)" "(make-float-vector 256 0.0)" "(make-int-vector 256 0)" "(make-complex-vector 256 0.0)"
		    "(make-vector '(2 3) 1)"             "(make-vector '(12 14) #<undefined>)"
		    "(make-byte-vector '(2 3) 1)"        "(make-byte-vector '(4 32) 255)"
		    "(make-string 256 #\\1)"             "(make-string 64 #\\a)"
		    "(make-int-vector '(2 3) 1)"         "(make-int-vector '(2 128) -1)"
		    "(make-float-vector '(2 3) 1)"       "(make-float-vector '(128 3) pi)" "(make-complex-vector '(128 3) 0+i)"
		    "(make-vector 3 'a symbol?)"         "(make-vector '(2 3 4 3 2 3 4) 1)"
		    "(make-vector 3 1+i complex?)"       "(make-vector (make-list 10 2))"
		    "(make-vector 3 #<eof> eof-object?)" "(make-vector (make-list 256 1))"
		    "(make-vector 3 '(1) pair?)"
		    "(make-vector 3 :rest keyword?)"
		    "(make-vector '(2 3) #f boolean?)"
		    "(make-vector '(2 3) 'a symbol?)"
		    "(make-hash-table 8 #f (cons symbol? integer?))"
		    "(make-weak-hash-table 8 #f (cons symbol? integer?))"
		    "(let ((i 32)) (set! (setter 'i) integer?) (curlet))"
		    "(let ((i 32)) (set! (setter 'i) integer?) (set! i 3) (curlet))"

		    "(make-vector 3 #f bool/int?)"
		    "(make-float-vector 3 1.0 (lambda (x) (< x pi)))"
		    "(make-int-vector 3 1 (lambda (x) (< x 3)))"
		    "(make-byte-vector 3 1 (lambda (x) (> x 0)))"
		    "(let ((a 1.0)) (set! (setter 'a) (let ((+signature+ '(boolean? #t))) (lambda (x) (real? x)))) (curlet))"
		    "(make-hash-table 8 #f (cons (lambda (x) (symbol? x)) (lambda (x) (integer? x))))"
		    "(make-vector 3 #f (lambda (x) #f))" ; if not an error, someone forgot to call it
		    "(make-hash-table 8 #f (cons (lambda (x) #f) (lambda (x) #f)))" ; same
		    "(make-vector 3 #f (let ((calls 0)) (lambda (x) (set! calls (+ calls 1)) (= calls 1))))" ; 2 calls = error I hope

		    "(write (list 1.0) (openlet (inlet 'write car)))"

		    "(immutable! #(1 2))" "(immutable! #r(1 2))" "(immutable! \"asdf\")" "(immutable! '(1 2))" "(immutable! (hash-table 'a 1))"
		    ;"(immutable! 'x)"
		    "(immutable! 'asdf)"
		    "(lambda (x) (fill! (copy x) 0))"

		    "(map (lambda (x) (catch #t (lambda () (vector->list x)) (lambda (t i) 'err))) (list #(1 2) 1))"
		    "(symbol-table)" ; (make-list 123 (symbol-table))!

		    "(cons-r 0 0 6)"
		    "(list-r 0 0 6)"

		    "(let loop ((i 2)) (if (> i 0) (loop (- i 1)) i))"

		    ;"(rootlet)" ; why was this commented out? -- very verbose useless diffs
		    ;"(unlet)"   ; same as above
		    "(let? (curlet))"

		    "(symbol (make-string 130 #\\a))" "(symbol \"a\" \"b\")"
		    "(symbol \"1\\\\\")" "#\\xff"  "#\\backspace" ":0" "(list (list 1 2) (cons 1 2))"
		    "#i2d((1 1 1) (2 2 2) (1 1 1))" "(subvector (vector 1 2 3 4 5 6) 0 6 '(2 3))"
		    "(let ((<1> (vector #f #f #f))) (set! (<1> 0) <1>) (set! (<1> 1) <1>) (set! (<1> 2) <1>) <1>)"
		    "#i3d(((1 2 3) (3 4 5)) ((5 6 1) (7 8 2)))"
		    "(hash-table +nan.0 1)" "#\\7" "(inlet :a (hash-table 'b 1))" "(openlet (immutable! (inlet :a 1)))"
		    "(subvector #i2d((1 2) (3 4)))" "(subvector #i2d((1 2) (3 4)) 0 4 '(4))" "(subvector #i2d((1 2) (3 4)) 1 3 '(2 1))"

		    "my-let" "my-with-baffle" "fvset" "htset"
		    "(catch #t (lambda () (+ 1 #(2))) (lambda (type info) 0))"
		    "~/cl/tmp1.r5rs"
		    (reader-cond (with-mock-data "(if (> (random 1.0) 0.5) _v_ _mv_)"))
		    "(set! (symbol-initial-value 'make-block) 123456789)"

		    ;"*s7*"     ;variable? and verbose if (for example) (_fnc9_ *s7*)
		    "(begin (real? (*s7* 'cpu-time)))" ; variable
		    "(*s7* 'c-types)"
		    ;"(copy (*s7* 'file-names))" ; one is *stdin* which can hang if read* gets it as the port
		    ;"(copy (*s7* 'gc-protected-objects))"  ; access + element set => not protected! perhaps copy it?
		    ;"(*s7* 'rootlet-size)"
		    "(begin (list? (*s7* 'catches)))"
		    "(begin (integer? (*s7* 'stack-top)))"
		    ;(reader-cond ((provided? 'debugging) "(when ((*s7* 'heap-size) < (ash 1 21)) (heap-analyze) (heap-scan 47))")) ;(+ 1 (random 47))))"))

		    "(begin (define (f x) (+ x 1)) (define (g x) (f x)) (define (f x) (+ x 2)) (g 1))"
;#|
		    "(*s7* 'accept-all-keyword-arguments)"
		    ;"(*s7* 'autoloading?)" ; require warnings
		    "(*s7* 'bignum-precision)"
		    ;"(*s7* 'catches)"
		    ;"(*s7* 'cpu-time)"
		    "(*s7* 'c-types)"
		    ;"(*s7* 'debug)" ; causes infinite output and rootlet id trouble??
		    "(*s7* 'default-hash-table-length)"
		    ;"(*s7* 'default-random-state)" ; useless diffs
		    "(*s7* 'default-rationalize-error)"
		    "(*s7* 'equivalent-float-epsilon)"
		    "(*s7* 'expansions?)"
		    ;"(*s7* 'filenames)"
		    ;"(*s7* 'file-names)"
		    ;"(*s7* 'float-format-precision)"
		    ;"(*s7* 'free-heap-size)"
		    ;"(*s7* 'gc-freed)"
		    ;"(*s7* 'gc-info)"
		    "(*s7* 'gc-protected-objects)"
		    "(*s7* 'gc-resize-heap-by-4-fraction)"
		    "(*s7* 'gc-resize-heap-fraction)"
		    ;"(*s7* 'gc-stats)"
		    ;"(*s7* 'gc-temps-size)" ; almost equivalent to calling (gc) anywhere (set! (*s7* 'gc-temps-size) 2)
		    ;"(*s7* 'gc-total-freed)"
		    "(*s7* 'hash-table-float-epsilon)"
		    ;"(*s7* 'hash-table-missing-key-value)" ; needs GC protection
		    "(*s7* 'heap-size)"
		    ;"(*s7* 'history)"
		    "(*s7* 'history-enabled)"
		    ;"(*s7* 'history-size)" ; if 1M, tests slow down to a near halt clearing history
		    "(*s7* 'initial-string-port-length)"
		    ;"(*s7* 'iterator-at-end-value)" ; needs GC protection
		    "(*s7* 'major-version)"
		    ;"(*s7* 'max-heap-size)"
		    ;"(*s7* 'max-list-length)"
		    ;"(*s7* 'max-string-port-length)" ; infinite output
		    ;"(*s7* 'max-stack-size)"
		    ;"(*s7* 'max-string-length)"
		    ;"(*s7* 'max-vector-dimensions)"
		    ;"(*s7* 'max-vector-length)"
		    ;"(*s7* 'memory-usage)" ; much printout
		    ;"(memory-rusage)"
		    "(*s7* 'minor-version)"
		    ;"(*s7* 'most-negative-fixnum)"
		    ;"(*s7* 'most-positive-fixnum)"
		    ;"(*s7* 'muffle-warnings?)" ; require warnings
		    (reader-cond ((provided? 'number-separator) "(*s7* 'number-separator)"))
		    "(*s7* 'openlets)"
		    "(*s7* 'output-file-port-length)"
		    "(*s7* 'print-length)"
		    ;"(*s7* 'profile)"
		    ;"(*s7* 'profile-info)"
		    ;"(*s7* 'profile-prefix)"
		    ;"(*s7* 'rootlet-size)"
		    ;"(*s7* 'safety)" ; if 0 lets circular bodies through
		    ;"(*s7* 'stack)" ; gets evaluated!
		    "(*s7* 'stacktrace-defaults)"
		    ;"(*s7* 'stack-size)"
		    ;"(*s7* 'stack-top)" ; stupid diffs
		    "(*s7* 'symbol-quote?)"
		    "(*s7* 'symbol-printer)"
		    ;"(*s7* 'undefined-constant-warnings)"
		    ;"(*s7* 'undefined-identifier-warnings)" ; infinite output
		    "(*s7* 'version)"
		    ;"(let->list *s7*)" ; to much uninteresting output
		    ;"(make-iterator *s7*)"
		    ;"(make-iterator (rootlet))"
		    ;"(make-iterator (symbol-table))"
;|#
		    #f #f #f ; cyclic here (see get-arg)
		    ))

      (codes (vector
	      (list (lambda (s) (string-append "(do ((x 0.0 (+ x 0.1)) (i 0 (+ i 1))) ((>= x .1) (with-immutable (i) " s ")))"))
		    (lambda (s) (string-append "(let ((x 0.1) (i 1)) (with-immutable (i) " s "))")))
	      (list (lambda (s) (string-append "(do ((x 0) (i 0 (+ i 1))) ((= i 1) x) (with-immutable (i) (set! x " s ")))"))
		    (lambda (s) (string-append "(let ((x 0) (i 0)) (with-immutable (i) (set! x " s ")))")))
	      (list (lambda (s) (string-append "(cond (else " s "))"))
                    (lambda (s) (string-append "(case x (else " s "))")))
	      (list (lambda (s) (string-append "(case false ((#f) " s "))"))
                    (lambda (s) (string-append "(case false ((1) #t) (else " s "))")))
;	      (list (lambda (s) (string-append "(with-let (rootlet) " s ")"))
;		    (lambda (s) (string-append "(with-let (sublet (rootlet)) " s ")")))
	      (reader-cond
	       (with-continuations
		(list (lambda (s) (string-append "(call-with-exit (lambda (_x_) " s "))"))
                      (lambda (s) (string-append "(call/cc (lambda (_x_) " s "))")))
		(list (lambda (s) (string-append "(let () (let-temporarily ((x 1234)) (call-with-exit (lambda (goto) (goto x))) " s "))"))
                      (lambda (s) (string-append "(let () (let-temporarily ((x 1234)) (call/cc (lambda (goto) (goto x))) " s "))")))))
	      (list (lambda (s) (string-append "(if (not x) (begin " s "))"))
                    (lambda (s) (string-append "(if x #<unspecified> (begin " s "))")))
	      (list (lambda (s) (string-append "(cond ((not false) " s "))"))
                    (lambda (s) (string-append "(unless false " s ")")))
	      (list (lambda (s) (string-append "(let () (let-temporarily ((x 1)) " s "))"))
                    (lambda (s) (string-append "(let ((x 1)) " s ")")))
	      (list (lambda (s) (string-append "(_let1_ " s ")"))
                    (lambda (s) (string-append "(_let2_ " s ")")))
	      (list (lambda (s) (string-append "(_dw_ " s ")"))
                    (lambda (s) (string-append "((lambda () " s "))")))
	      (list (lambda (s) (string-append "(append " s ")"))
                    (lambda (s) (string-append "(apply append (list " s "))")))
	      (list (lambda (s) (string-append "(with-let (inlet 'i 0) " s ")"))
                    (lambda (s) (string-append "(with-let (inlet) (let ((i 0)) " s "))")))
	      (list (lambda (s) (string-append "(list (_cw_ " s "))"))
                    (lambda (s) (string-append "(list (values " s "))")))
	      (list (lambda (s) (string-append "(do () ((not false) " s "))"))
                    (lambda (s) (string-append "(when (not false) " s ")")))
	      (list (lambda (s) (string-append "(for-each display (list " s "))")) ; current-output-port is #f (set below)
                    (lambda (s) (string-append "(for-each (lambda (x) (display x)) (list " s "))")))
	      (list (lambda (s) (string-append "(_ct1_ " s ")"))
                    (lambda (s) (string-append "(_ct2_ " s ")")))
	      (list (lambda (s) (string-append "(with-output-to-string (lambda () " s "))"))
                    (lambda (s) (string-append "(_dw_out_ " s ")")))
	      (list (lambda (s) (string-append "(_rf1_ " s ")"))
                    (lambda (s) (string-append "(_rf2_ " s ")")))
	      (list (lambda (s) (string-append "(_rf1_ " s ")"))
                    (lambda (s) (string-append "(_rf3_ " s ")")))
	      (list (lambda (s) (string-append "(_do1_ " s ")"))
                    (lambda (s) (string-append "(_do2_ " s ")")))
	      (list (lambda (s) (string-append "(let ((lt (inlet 'a 1))) (set! (with-let lt a) " s "))"))
		    (lambda (s) (string-append "(let ((lt (inlet 'a 1))) (set! (lt 'a) " s "))")))
	      (list (lambda (s) (string-append "(let ((lt (inlet 'a 1))) (set! (with-let ((curlet) 'lt) a) " s "))"))
		    (lambda (s) (string-append "(let ((lt (inlet 'a 1))) (set! (lt 'a) " s "))")))
	      (list (lambda (s) (string-append "(set! (_dl_) " s ")"))
		    (lambda (s) (string-append "(let ((v (vector 0))) (set! (v 0) " s "))")))
	      (list (lambda (s) (string-append "(let ((x 1)) (immutable! 'x) (begin " s "))"))
                    (lambda (s) (string-append "((lambda* ((x 1)) (immutable! 'x) " s "))")))
	      (list (lambda (s) (string-append "(let ((f (lambda* (a (b 1)) (+ a b)))) (f :a " s "))"))
		    (lambda (s) (string-append "(let ((f (lambda* (a (b 1)) (+ a b)))) (f a: " s "))")))
	      (list (lambda (s) (string-append "(do ((i 0 (+ i 1))) ((= i 1)) (do ((j 0 (+ j 1))) ((= j 1)) (with-immutable (i j) " s ")))"))
                    (lambda (s) (string-append "(do ((i 0 (+ i 1))) ((= i 1)) (let ((j 0)) (with-immutable (i j) " s ")))")))
	      (list (lambda (s) (string-append "(or (_cop1_ " s "))"))
                    (lambda (s) (string-append "(and (_cop2_ " s "))")))
	      (list (lambda (s) (string-append "(_do4_ " s ")"))
                    (lambda (s) (string-append "(_do5_ " s ")")))
	      (list (lambda (s) (string-append "(_ft1_ " s ")"))
                    (lambda (s) (string-append "(_ft2_ " s ")")))
;	      (list (lambda (s) (string-append "(_rd3_ " s ")"))
;                   (lambda (s) (string-append "(_rd4_ " s ")")))
;	      (list (lambda (s) (string-append "(_rd5_ " s ")"))
;                   (lambda (s) (string-append "(_rd6_ " s ")")))
;	      (list (lambda (s) (string-append "(_rd7_ " s ")"))
;                   (lambda (s) (string-append "(_rd8_ " s ")")))
;	      (list (lambda (s) (string-append "(format #f \"~S\" (list " s "))"))
;		    (lambda (s) (string-append "(object->string (list " s "))")))
;	      (list (lambda (s) (string-append "(_wr1_ " s ")"))
;                   (lambda (s) (string-append "(_wr2_ " s ")")))
;	      (list (lambda (s) (string-append "(_wr3_ " s ")"))
;                   (lambda (s) (string-append "(_wr4_ " s ")")))
	      (list (lambda (s) (string-append "(vector " s ")"))
                    (lambda (s) (string-append "(apply vector (list " s "))")))
	      (list (lambda (s) (string-append "(hash-table 'a " s ")"))
                    (lambda (s) (string-append "(apply hash-table (list 'a " s "))")))
	      (list (lambda (s) (string-append "(weak-hash-table 'a " s ")"))
                    (lambda (s) (string-append "(apply weak-hash-table (list 'a " s "))")))
;	      (list (lambda (s) (string-append "(byte-vector " s ")"))
;                   (lambda (s) (string-append "(apply byte-vector (list " s "))")))
	      (list (lambda (s) (string-append "(values " s ")"))
                    (lambda (s) (string-append "(apply values (list " s "))")))
	      (list (lambda (s) (string-append "(vector (values " s "))"))
                    (lambda (s) (string-append "(apply vector (list " s "))")))
	      (list (lambda (s) (string-append "(vector 1 (values " s "))"))
                    (lambda (s) (string-append "(apply vector (list 1 " s "))")))
	      (list (lambda (s) (string-append "(do ((i 0 (+ i 1))) ((= i 1)) (with-immutable (i) " s "))"))
                    (lambda (s) (string-append "(let ((__x__ 1)) (do ((i 0 (+ i __x__))) ((= i __x__)) (with-immutable (i) " s ")))")))
	      (list (lambda (s) (string-append "(cond ((eqv? x 0) " s "))"))
                    (lambda (s) (string-append "(when (eqv? x 0) " s ")")))
              (list (lambda (s) (string-append "((lambda (a) (and (int-vector? a) (sort! a >))) " s ")"))
                    (lambda (s) (string-append "((lambda (a) (and (int-vector? a) (sort! a (lambda (x y) (not (<= x y)))))) " s ")")))
	      (list (lambda (s) (string-append "(_iter_ " s ")"))
                    (lambda (s) (string-append "(_map_ " s ")")))
	      (list (lambda (s) (string-append "(_cat1_ " s ")"))
                    (lambda (s) (string-append "(_cat2_ " s ")")))
	      (list (lambda (s) s)
                    (lambda (s) (string-append "(begin " s ")")))
;	      (list (lambda (s) (string-append "(let ((+ *)) " s ")"))
;                   (lambda (s) (string-append "(let () (define + *) " s ")")))
;	      (list (lambda (s) (string-append "(let ((+ *)) (let ((cons list)) " s "))"))
;                   (lambda (s) (string-append "(let ((cons list)) (let ((+ *)) " s "))")))
;	      (list (lambda (s) (string-append "(let () (with-baffle " s "))"))
;                   (lambda (s) (string-append "(let ((mwb with-baffle)) (mwb " s "))")))
	      (list (lambda (s) (string-append "(let _L_ ((x 1)) (if (> x 0) (_L_ (- x 1)) " s "))"))
                    (lambda (s) (string-append "(let* _L_ ((x 1)) (if (> x 0) (_L_ (- x 1)) " s "))")))
	      (list (lambda (s) (string-append "(catch #t (lambda () (+ 1 #\\a)) (lambda (+t+ +i+) " s "))"))
                    (lambda (s) (string-append "(catch #t (lambda () " s ") (lambda (type info) 'error))")))
	      (list (lambda (s) (string-append "(let-temporarily ((x (list " s "))) x)"))
		    (lambda (s) (string-append "(let ((x (list " s "))) x)")))
	      (list (lambda (s) (string-append "(case 1 ((2 3 1) " s ") (else 'oops))"))
		    (lambda (s) (string-append "(cond ((= 1 1) " s ") (else 'oops))")))
	      (list (lambda (s) (string-append "(let ((one 1)) (case one ((2 3 1) => (lambda (i) " s ")) (else 'oops)))"))
		    (lambda (s) (string-append "(let ((one 1)) (cond (one => (lambda (i) " s ")) (else 'oops)))")))
	      (list (lambda (s) (string-append "(catch #t (lambda () (let-temporarily ((x (list " s "))) x)) (lambda (type info) 'error))"))
		    (lambda (s) (string-append "(catch #t (lambda () (let ((x (list " s "))) x)) (lambda (type info) 'error))")))
	      (list (lambda (s) (string-append "(do ((i 0 (+ i 1))) ((= i 1)) (with-immutable (i) " s "))"))
                    (lambda (s) (string-append "(do ((j 0 (+ j 1))) ((= j 1)) (do ((i 0 (+ i 1))) ((= i 1)) (with-immutable (i j) " s ")))")))
	      (list (lambda (s) (string-append "(do ((i 0 (- i 1))) ((= i -1)) (with-immutable (i) " s "))"))
                    (lambda (s) (string-append "(do ((j 0 (+ j 1))) ((= j 1)) (do ((i 0 (- i 1))) ((= i -1)) (with-immutable (i j) " s ")))")))
	      (list (lambda (s) (string-append "(do ((i -10 (+ i 1))) ((= i 0)) (with-immutable (i) " s "))"))
                    (lambda (s) (string-append "(do ((j 0 (+ j 1))) ((= j 1)) (do ((i -10 (+ i 1))) ((= i 0)) (with-immutable (i j) " s ")))")))
	      (list (lambda (s) (string-append "(do ((i -5 (+ i 1))) ((= i 5)) (with-immutable (i) " s "))"))
                    (lambda (s) (string-append "(do ((j 0 (+ j 1))) ((= j 1)) (do ((i -5 (+ i 1))) ((= i 5)) (with-immutable (i j) " s ")))")))
;	      (list (lambda (s) (string-append "(do ((i 0 (+ i 1))) ((= i 1)) (with-immutable (i) (apply values " s " ())))"))
;                    (lambda (s) (string-append "(do ((j 0 (+ j 1))) ((= j 1)) (do ((i 0 (+ i 1))) ((= i 1)) (with-immutable (i j) (apply values " s " ()))))")))
	      (list (let ((last-s "#f")) (lambda (s) (let ((res (string-append "(if (car (list " last-s ")) (begin " s "))"))) (set! last-s s) res)))
                    (let ((last-s "#f")) (lambda (s) (let ((res (string-append "(if (not (car (list " last-s "))) #<unspecified> (begin " s "))"))) (set! last-s s) res))))
	      (list (lambda (s) (string-append "(let* ((s1 (begin " s ")) (s2 (copy s1))) (member s1 (list s2)))"))
                    (lambda (s) (string-append "(let* ((s1 (begin " s ")) (s2 (copy s1))) (member s1 (list s2) fequal?))")))
	      (list (lambda (s) (string-append "(iterate (make-iterator (vector " s ")))"))
		    (lambda (s) (string-append "(car (list " s "))")))
	      (list (lambda (s) (string-append "(let* ((obj (car (list " s "))) (I1 (make-iterator obj)) (I2 (make-iterator (copy obj)))) (I1) (equal? I1 I2))"))
		    (lambda (s) (string-append "(let* ((obj (car (list " s "))) (I1 (make-iterator obj)) (I2 (make-iterator (copy obj)))) (I2) (equivalent? I1 I2))")))
	      (list (lambda (s) (string-append "(call-with-exit (lambda (return) (return " s ")))"))
		    (lambda (s) (string-append "((lambda () (values " s ")))")))
	      (list (lambda (s) (string-append "(let ((x #f)) (for-each (lambda (y) (set! x y)) (list " s ")) x)"))
		    (lambda (s) (string-append "((lambda (x) (for-each (lambda y (set! x (car y))) (list " s ")) x) #f)")))
	      (list (lambda (s) (string-append "(list (let () (let-temporarily (((*s7* 'openlets) #f)) " s ")))"))
                    (lambda (s) (string-append "(list (let ((old #f)) (dynamic-wind (lambda () (set! old (*s7* 'openlets)) (set! (*s7* 'openlets) #f)) (lambda () " s ") (lambda () (set! (*s7* 'openlets) old)))))")))
	      (list (lambda (s) (string-append "(list (let () (let-temporarily (((*s7* 'safety) 1)) " s ")))"))
                    (lambda (s) (string-append "(list (let ((old #f)) (dynamic-wind (lambda () (set! old (*s7* 'safety)) (set! (*s7* 'safety) 1)) (lambda () " s ") (lambda () (set! (*s7* 'safety) old)))))")))
	      (list (lambda (s) (string-append "(map Hk (list " s "))"))
		    (lambda (s) (string-append "(map _dilambda_ (list " s "))")))
	      (list (lambda (s) (string-append "(let ((cc (call/cc (lambda (c) c)))) (if (continuation? cc) (cc (list " s ")) cc))"))
		    (lambda (s) (string-append "(let ((cc (call-with-exit (lambda (c) c)))) (if (goto? cc) (list " s ")))")))
;	      (list (lambda (s) (string-append "(let ((e (openlet (inlet :abs (lambda (a) (- a 1)))))) (with-let e " s "))"))
;		    (lambda (s) (string-append "(let ((abs (lambda (a) (- a 1)))) " s ")")))
;	      (list (lambda (s) (string-append "(let ((m23 (macro () " s "))) (list (m23)))")) ; list for values
;		    (lambda (s) (string-append "(let ((b23 (bacro () " s "))) (list (b23)))")))

	      ;; perhaps function port (see _rd3_ for open-input-string), gmp?
	      ))

      (chars (vector #\( #\( #\) #\space))) ; #\' #\/ #\# #\, #\` #\@ #\. #\:))  ; #\\ #\> #\space

  (let ((clen (length chars))
	(flen (length functions))
	(alen (length args))
	(codes-len (length codes))
	(args-ran (+ 1 (random 5)))
	(both-ran (+ 3 (random 8))))

    (define (get-arg)
      (let ((str (args (random alen))))
	(if (string? str) ; else #f -> cyclic struct
	    str
	    (cycler (+ 3 (random 3))))))

    (define (rf-symbol->string sym)
      (cond ((or (> (random 100) 5)
		 (syntax? sym)
		 (syntax? (symbol->value sym)))
             (symbol->string sym))
            ((< (random 10) 3)
             (string-append "(let () " (symbol->string sym) ")"))
            ((< (random 10) 3)
             (string-append "((vector " (symbol->string sym) ") 0)"))
            (else (string-append "#_" (symbol->string sym)))))

    (define (fix-op op)
      (case op
	;((set!) "set! _definee_") ;"set!") ; block set! of our vars??
	((let) "let ()")   ; need to block infinite loops like (let abs () (abs))
	((let*) "let* ()")
	;((do) "_do3_")
	;((call-with-output-file) "call-with-output-file \"/dev/null\" ")
	;((with-output-to-file) "with-output-to-file \"/dev/null\" ")
	((define define* define-macro define-macro* define-bacro define-bacro*) (format #f "~A _definee_ " op))
	((eval) "checked-eval")
	((ifa) "(if (integer? _definee_) + -)")
	((ifb) "(if (integer? _definee_) when unless)")
	(else => rf-symbol->string)))

    (define make-expr
      (let ((parens 1)
	    (dqs 0)
	    (j 1)
	    (str (make-string 8192 #\space)))
	(lambda (size)
	  (set! parens 1)
	  (set! dqs 0)
	  (set! j 1)
	  ;(fill! str #\space)
	  (set! (str 0) #\()

          (let ((opstr (fix-op (functions (random flen)))))
            (string-copy opstr str j)
            (set! j (+ j (length opstr))))

	  (set! (str j) #\space)
	  (set! j (+ j 1))

	  (do ((k 1 (+ k 1)))
	      ((= k size))

	    (set! (str j) (chars (random clen)))
	    (if (= dqs 1)
		(if (and (char=? (str j) #\")
			 (or (= j 0)
			     (not (char=? (str (- j 1)) #\\))))
		    (set! dqs 0))

		;; else not in a string constant
		(case (str j)
		  ((#\()
		   (set! parens (+ parens 1))

                   (let ((opstr (fix-op (functions (random flen)))))
                     (string-copy opstr str (+ j 1))
                     (set! j (+ j 1 (length opstr))))
		   (set! (str j) #\space))

		  ((#\))
		   (set! parens (- parens 1))
		   (when (negative? parens)
		     (set! (str j) #\space)
		     (set! parens 0)))

		  ((#\space)
		   (let ((nargs (random args-ran)))
		     (do ((n 0 (+ n 1)))
			 ((= n nargs))

                       (let ((argstr (get-arg)))
                         (string-copy argstr str (+ j 1))
                         (set! j (+ j (length argstr) 1)))
		       ;(set! j (+ j 1))
		       (set! (str j) #\space))))

		  ((#\")
		   (set! dqs 1))))

	    (set! j (+ j 1)))

	  (if (= dqs 1)
	      (set! (str j) #\"))

	  (if (> parens 0)
	      (do ((k parens (- k 1))
		   (n j (+ n 1)))
		  ((= k 0)
		   (set! j n))
		(string-set! str n #\))))

	  (substring str 0 j))))

    (define type-eqv?
      (let ()
	(define (local-type-of obj)
	  (if (openlet? obj)
	      (catch #t
		(lambda ()
		  (type-of (obj 'value)))
		(lambda (type info)
		  'let?))
	      (type-of obj)))
	(lambda (v1 v2 v3 v4)
	  (let ((v1-type (local-type-of v1)))
	    (and (or (eq? v1-type (local-type-of v2)) (and (number? v1) (number? v2) (= v1 v2)))
		 (or (eq? v1-type (local-type-of v3)) (and (number? v1) (number? v3) (= v1 v3)))
		 (or (eq? v1-type (local-type-of v4)) (and (number? v1) (number? v4) (= v1 v4))))))))

    (define (show-variables str)
      (if (string-position "int-var" str) (format *stderr* "int-var: ~W~%" int-var))
      (if (string-position "float-var" str) (format *stderr* "float-var: ~W~%" float-var))
      (if (string-position "ratio-var" str) (format *stderr* "ratio-var: ~W~%" ratio-var))
      (if (string-position "complex-var" str) (format *stderr* "complex-var: ~W~%" complex-var))
      (if (string-position "imi" str) (format *stderr* "imi: ~W~%" imi))
      (if (string-position "_definee_" str) (format *stderr* "_definee_: ~W~%" _definee_))

      (if (string-position "a1" str) (format *stderr* "a1: ~W~%" a1))
      (if (string-position "a2" str) (format *stderr* "a2: ~W~%" a2))
      (if (string-position "a3" str) (format *stderr* "a3: ~W~%" a3))
      (if (string-position "a4" str) (format *stderr* "a4: ~W~%" a4))
      (newline *stderr*)

      (let ((tree (catch #t
		    (lambda () ; try to catch read errors
		      (eval-string (string-append "'" str)))
		    ;;(with-input-from-string str read) -- causes missing close paren troubles with eval-time reader-cond (read error not caught)
		    (lambda (t i)
		      ()))))
	(let walker ((p tree))
	  (if (symbol? p)
	      (if (or (setter p) (setter (symbol->value p)))
		  (format *stderr* "(~S ~S ~S) " p (symbol->value p) (or (setter p) (setter (symbol->value p))))
		  (format *stderr* "(~S ~S) " p (symbol->value p)))
	      (when (pair? p)
		(walker (car p))
		(walker (cdr p)))))))

    (define (same-type? val1 val2 val3 val4 str str1 str2 str3 str4)
      (cond ((not (type-eqv? val1 val2 val3 val4))
	     (unless (or (memq error-type '(out-of-range wrong-type-arg baffled!))
			 ;; _rd3_ vs _rd4_ for example where one uses dynamic-wind which has built-in baffles
			 (and (number? val1)
			      (or (nan? val1)
				  (infinite? val1)
				  (and (equivalent? val1 val2)
				       (equivalent? val1 val3)
				       (equivalent? val1 val4))))
			 (equal? val1 "0")
			 ;(string-position "set! _definee_" str)
			 (and (iterator? _definee_)
			      (string-position "_definee_" str)))
	       (let ((errstr (and (or (eq? val1 'error)
				      (eq? val2 'error)
				      (eq? val3 'error)
				      (eq? val4 'error))
				  (format #t "    from same-type type-eqv: ~S: ~S~%"
					  error-type
					  (if (pair? error-info)
					      (catch #t
						(lambda ()
						  (tp (apply #_format #f error-info)))
						(lambda (type info)
						  error-info))
					      error-info)))))
		 (set! error-info #f)
		 (set! error-code "")
		 (unless (and errstr
			      (or (not (string? errstr))
				  (string-position "unbound" errstr)
				  (string-position "circular" errstr)))
		   (when (string-position "_definee_" str) (format *stderr* "_definee_: ~W~%" old-definee))
		   (when (string-position "bigrat" str) (format *stderr* "bigrat: ~W" bigrat))
		   (when (string-position "-inf.0" str) (format *stderr* "-inf.0: ~W" -inf.0))
		   (show-variables str)
		   (format *stderr* "1695: ~%~%~S~%~S~%~S~%~S~%    ~A~%    ~A~%    ~A~%    ~A~%"
			   str1 str2 str3 str4
			   (tp val1) (tp val2) (tp val3) (tp val4))
		   (if (string? errstr) (display errstr *stderr*))
		   ;(abort)
		   ))))

	    ((or (catch #t
		   (lambda ()
		     (and (or (openlet? val1)
			      (openlet? val3))
			  (equivalent? v1 v2)
			  (equivalent? v1 v3)
			  (equivalent? v1 v4)))
		   (lambda args
		     #t)) ; (openlet? (openlet (inlet 'openlet? ()))) -> error: attempt to apply nil to (inlet 'openlet? ())
		 (string-position "(set!" str1)
		 (string-position "gensym" str1)))

	    ((symbol? val1)
	     (if (gensym? val1)
		 (unless (and (gensym? val2)
			      (gensym? val3)
			      (gensym? val4))
		   (format *stderr* "1717: ~%~%~S~%~S~%~S~%~S~%~S~%   ~A ~A ~A ~A~%"
			   str str1 str2 str3 str4
			   (tp val1) (tp val2) (tp val3) (tp val4)))
		 (unless (and (eq? val1 val2)
			      (eq? val1 val3)
			      (eq? val1 val4))
		   (when (string-position "_definee_" str) (format *stderr* "_definee_: ~W~%" old-definee))
		   (show-variables str)
		   (format *stderr* "1725: ~%~%~S~%~S~%~S~%~S~%~S~%   ~A ~A ~A ~A~%"
			   str str1 str2 str3 str4
			   (tp val1) (tp val2) (tp val3) (tp val4))
		   (if (or (eq? val1 'error)
			   (eq? val2 'error)
			   (eq? val3 'error)
			   (eq? val4 'error))
		       (catch #t
			 (lambda ()
			   (show-variables str)
			   (format *stderr* "    from same-type symbol: ~S: ~S~%" error-type
				   (if (and (pair? error-info)
					    (string? (car error-info)))
				       (tp (catch #t
					     (lambda ()
					       (apply #_format #f error-info))
					     (lambda (type info)
					       (format *stderr* "format error symbol? in same-type\n"))))
				       error-info)))
			 (lambda args
			   (format *stderr* "error in format in t725: ~S~%" (list str val1 val2 val3 val4))))))))

	    ((sequence? val1) ; there are too many unreadable/unequivalent-but the same cases to check these by element (goto, continuation, ...)
	     (let ((len1 (length val1)))
	       (unless (or (provided? 'gmp)
			   (let? val1)
			   (hash-table? val1)
			   (and (eqv? len1 (length val2))
				(eqv? len1 (length val3))
				(eqv? len1 (length val4)))
			   (and (string? val1)
				(string->number val1))
			   ;(string-position "set! _definee_" str)
			   (and (iterator? _definee_)
				(string-position "_definee_" str)))
		 (when (string-position "_definee_" str) (format *stderr* "_definee_: ~W~%" old-definee))
		 (show-variables str)
		 (format *stderr* "1762: ~%~%~S~%~S~%~S~%~S~%~S~%    ~A~%    ~A~%    ~A~%    ~A~%~%"
			 str str1 str2 str3 str4
			 (tp val1) (tp val2) (tp val3) (tp val4)))))

	    ((number? val1)
	     (when (or (and (nan? val1)
			    (not (and (nan? val2) (nan? val3) (nan? val4))))
		       (and (infinite? val1)
			    (not (and (infinite? val2) (infinite? val3) (infinite? val4))))
		       (and (finite? val1)
			    (not (and (finite? val2) (finite? val3) (finite? val4))))
		       (and (not (= val1 val2))
			    (not (zero? val1))
			    (finite? val1) (real? val1) (real? val2) (real? val3) (real? val4)
			    (or (and (negative? val1) (or (positive? val2) (positive? val3) (positive? val4)))
				(and (positive? val1) (or (negative? val2) (negative? val3) (negative? val4))))))
	       (show-variables str)
	       (format *stderr* "1779: ~%~%~S~%~S~%~S~%~S~%~S~%    ~A~%    ~A~%    ~A~%    ~A~%~%"
		       str str1 str2 str3 str4
		       (tp val1) (tp val2) (tp val3) (tp val4))))

	    ((or (boolean? val1)
		 (syntax? val1)
		 (unspecified? val1)
		 (char? val1)
		 (memq val1 '(#<eof> ())))
	     (unless (or (and (eq? val1 val2)
			      (eq? val1 val3)
			      (eq? val1 val4))
			 ;(string-position "set! _definee_" str)
			 (and (iterator? _definee_)
			      (string-position "_definee_" str)))
	       (when (string-position "_definee_" str) (format *stderr* "_definee_: ~W~%" old-definee))
	       (show-variables str)
	       (format *stderr* "1796: ~%~%~S~%~S~%~S~%~S~%~S~%   ~A ~A ~A ~A~%"
		       str str1 str2 str3 str4
		       (tp val1) (tp val2) (tp val3) (tp val4))))

	    ((or (undefined? val1)
		 (c-object? val1))
	     (unless (and (equal? val1 val2)
			  (equal? val1 val3)
			  (equal? val1 val4))
	       (show-variables str)
	       (format *stderr* "1806: ~%~%~S~%~S~%~S~%~S~%~S~%   ~A ~A ~A ~A~%"
		       str str1 str2 str3 str4
		       (tp val1) (tp val2) (tp val3) (tp val4))))
	  ))

    (define (eval-it str)
      ;(format *stderr* "str: ~S~%" str)
      (set! (current-output-port) #f)
      (set! estr str)
      (set! old-definee _definee_)
      (when (and with-mock-data (output-port? imfo)) (get-output-string imfo #t))
      (catch #t
	(lambda ()
	  (car (list (eval-string str))))
	(lambda (type info)
	  (set! error-type (copy type))
	  (set! error-info (copy info))
	  (set! error-code (string-copy str))
	  (when (and last-error-type
		     (not (eq? error-type last-error-type)))
	    ;(format *stderr* "~S ~S~%" last-error-type error-type)
	    (set! last-error-type error-type))
	  (when (eq? type 'stack-too-big)
					;     (not (string-position "lambda" str)))
	    (format *stderr* "stack overflow from ~S~%" str)
	    (abort))
	  (when (eq? type 'heap-too-big)
	    (format *stderr* "heap overflow from ~S~%" str)
	    (pretty-print (*s7* 'memory-usage) *stderr*)
	    (newline *stderr*)
	    (format *stderr* "gc -> ")
	    (do ((x 0.0) (i 0 (+ i 1))) ((= i 256)) (set! x (complex i i))) ; clear temps
	    (gc) (gc)
	    (pretty-print (*s7* 'memory-usage) *stderr*)
	    (newline *stderr*)
	    (display "stopping t725...\n" *stderr*)
	    (abort)) ; to keep Linux from killing the X server!
	  (unless (or (not (eq? type 'read-error))
		      (string-position "junk" (car info))
		      (string-position "clobbered" (car info))
		      (string-position "unexpected" (car info))
		      (string-position "eval-string" str))
	    ;; "unexpected" close paren from: (eval-string (reverse (object->string ()))) -> (eval-string ")(")
	    (if (and (pair? info) (string? (car info)))
		(format *stderr* "read-error from ~S: ~S~%" str (catch #t
								  (lambda ()
								    (apply #_format #f info))
								  (lambda args
								    (format *stderr* "eval-it: inner format error\n"))))
		(format *stderr* "read-error bad info\n")))
          'error)))

    (define (try-both str)
      ;(format *stderr* "~A~%" str)
      ;(if (string-position " # " str) (format *stderr* "try-both: ~A~%" str))
      ;(if (> (random 1000) 990) (gc))
      (set! nostr estr)
      (set! ostr str)
      (set! (current-output-port) #f)

      (if (> (random 1.0) 0.5)
	  (begin
	    (set! int-var (random (ash 1 30)))
	    (set! float-var (random 1.0e10))
	    (set! ratio-var (/ (random (ash 1 30)) (+ 1 (random (ash 1 30)))))
	    (set! complex-var (complex (random 1.0e10) (random 1.0e10))))
	  (begin
	    (set! int-var (random (ash 1 30)))
	    (set! float-var (random -1.0e10))
	    (set! ratio-var (/ (random (- (ash 1 30))) (+ 1 (random (ash 1 30)))))
	    (set! complex-var (complex (random -1.0e10) (random -1.0e10)))))

      (catch #t
	(lambda ()
	  (set! curstr str)
	  ;; this is not the missing ) problem
	  (s7-optimize (list (catch #t
			       (lambda ()
				 (with-input-from-string str read))
			       (lambda args ())))))
	(lambda args 'error))

      (set! last-error-type #f)
      (let* ((outer-funcs (codes (random codes-len)))
	     (str1 (string-append "(let ((x #f) (i 0)) " ((car outer-funcs) str) ")"))
	     (str2 (string-append "(let () (define (func) " str1 ") (func) (func))"))
	     (str3 (string-append "(let ((x #f) (i 0)) " ((cadr outer-funcs) str) ")"))
	     (str4 (string-append "(let () (define (func) " str3 ") (func) (func))")))
	(let ((val1 (begin (set! curstr str1) (eval-it str1)))
	      (val2 (begin (set! curstr str2) (eval-it str2)))
	      (val3 (begin (set! curstr str3) (eval-it str3)))
	      (val4 (begin (set! curstr str4) (eval-it str4))))
	  ;(gc) (gc)
	  (set! (*s7* 'print-length) 4096)
	  (same-type? val1 val2 val3 val4 str str1 str2 str3 str4))
	(set! last-func outer-funcs))

      (when (setter Hk) (set! (setter Hk) #f))
      ;(unless (output-port? imfo) (format *stderr* "(new) imfo ~S -> ~S~%" estr imfo) (abort)) ; with-mock-data
      (set! *features* (copy %features%))
      (set! error-info #f)
      (set! error-type 'no-error)
      (set! error-code "")
      (set! x 0)
      )

    (define dots (vector "." "-" "+" "-" "." "-" "+" "-"))
    (define (test-it)
      (do ((m 0 (+ m 1))
	   (n 0))
	  (#f
	   (format *stderr* "reached end of loop??~%"))

	(when (= m 100000)
	  (set! m 0)
	  (set! n (+ n 1))
	  (when (= n 8)
	    (set! n 0)
	    (format *stderr* " ~A " (daytime))
	    )
	  (format *stderr* "~A" (vector-ref dots n)))

	(catch #t
	  (lambda ()
	    (try-both (make-expr (+ 1 (random both-ran))))) ; min 1 here not 0, was 6
	  (lambda (type info)
	    (apply format *stderr* info)
	    ))))

    (test-it)))
)

#|
functions currently omitted (from functions vector):
unlet owlet *read-error-hook* set-current-output-port immutable! system close-output-port exit
[port-filename] load string->keyword dynamic-unwind emergency-exit read set-current-error-port *autoload-hook*
gc abort open-output-file set-current-input-port [pair-line-number pair-filename] coverlet delete-file curlet

[read-line] [funclet] [port-line-number] [read-string] [varlet] [random-state] [random] [hash-code] [random-state->list] [current-input-port]
[make-string] [symbol-table] [current-error-port] [eval] [read-byte] [stacktrace] [read-char] [reverse!] [procedure-source] [*function*]
[provide] [rootlet] [symbol->dynamic-value] [set-cdr!] [make-hook]
|#
