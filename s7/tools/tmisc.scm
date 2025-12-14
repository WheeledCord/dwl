(set! (*s7* 'heap-size) (* 2 1024000))

;;; -------- for-each and map --------

(define (fe-test size)
  (let ((str (make-string size #\a)))
    (for-each char-alphabetic? str)
    (for-each (lambda (c) (char-alphabetic? c)) str))

  (let ((byt (make-byte-vector size 10)))
    (for-each abs byt)
    (for-each (lambda (b) (abs b)) byt))

  (let ((byt (make-int-vector size 10)))
    (for-each abs byt)
    (for-each (lambda (b) (abs b)) byt))

  (let ((byt (make-float-vector size 10)))
    (for-each abs byt)
    (for-each (lambda (b) (abs b)) byt))

  (let ((byt (make-vector size 10)))
    (for-each abs byt)
    (for-each (lambda (b) (abs b)) byt))

  (let ((lst (make-list size 10)))
    (for-each abs lst)
    (for-each (lambda (b) (abs b)) lst))

  (when (defined? 'make-block)
    (let ((byt (make-block size 10)))
      (for-each abs byt)
      (for-each (lambda (b) (abs b)) byt)))
  )

(fe-test 3000000)

(define (map-test size)
  (let* ((str (make-string size #\a))
	 (result (apply string (map (lambda (c) #\b) str))))
    (unless (string=? result (make-string size #\b))
      (format *stderr* "map string failed\n")))

  (let* ((str (make-byte-vector size 10))
	 (result (apply byte-vector (map (lambda (c) 11) str))))
    (unless (equal? result (make-byte-vector size 11))
      (format *stderr* "map byte-vector failed\n")))

  (let* ((str (make-int-vector size 10))
	 (result (apply int-vector (map (lambda (c) 11) str))))
    (unless (equal? result (make-int-vector size 11))
      (format *stderr* "map int-vector failed\n")))

  (let* ((str (make-float-vector size 10))
	 (result (apply float-vector (map (lambda (c) 11) str))))
    (unless (equal? result (make-float-vector size 11))
      (format *stderr* "map float-vector failed\n")))

  (let* ((str (make-vector size 10))
	 (result (apply vector (map (lambda (c) 11) str))))
    (unless (equal? result (make-vector size 11))
      (format *stderr* "map vector failed\n"))))

(map-test 500000)


(define size 500000)

;;; -------- let-temporarily --------
(define (w1 x)
  (let ((y x))
    (do ((j 0 (+ j 1)))
	((= j 1))
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(let-temporarily ((y 32))
	  (unless (= y 32)
	    (format *stderr* "temp y: ~A~%" y)))
	(unless (= y x)
	  (format *stderr* "y: ~A~%" y))))))

(define-constant (w2)
  (let ((x 1))
    (let ((y (let-temporarily ((x 32))
	       (+ x 1))))
      (+ x y))))

(define-constant (w3)
  (let ((x 1)
	(y 2))
    (let ((z (let-temporarily ((x 6) (y 7))
	       (+ x y))))
      (+ x y z))))

(define (w4)
  (let ((y (let-temporarily (((*s7* 'print-length) 32))
	     (*s7* 'print-length))))
    (+ y 1)))

(define (wtest)
  (w1 3)
  (unless (= (w2) 34) (format *stderr* "w2 got ~S~%" (w2)))
  (unless (= (w3) 16) (format *stderr* "w3 got ~S~%" (w3)))
  (do ((i 0 (+ i 1)))
      ((= i size))
    (w2)
    (w3)))


;;; -------- implicit/generalized set! --------

(define (fs1)
  (let-temporarily (((*s7* 'print-length) 8))
    123))

(define (fs2)
  (let ((x 32)) 
    (set! ((curlet) 'x) 3)
    x))

(define (fs3)
  (set! (with-let (curlet) (*s7* 'print-length)) 16)
  (*s7* 'print-length))

(define (fs4)
  (let ((e (inlet :v (vector 1 2))))
    (set! (with-let e (v 0)) 'a)
    (e 'v)))

(define (fs5)
  (let ((v (vector (inlet 'a 0))))
    (set! (v 0 'a) 32)
    ((v 0) 'a)))

(define (fs6)
  (let ((e (inlet 'x (inlet 'b 2))))
    (set! (e 'x 'b) 32)
    ((e 'x) 'b)))

(define (fs7)
  (let ((L (list (list 1 2)))) 
    (set! (L 0 0) 3)
    L))

(define (fs8)
  (let ((H (hash-table 'a (hash-table 'b 2))))
    (set! (H 'a 'b) 32)
    ((H 'a) 'b)))

(define (fs9)
  (let ((v (vector 1 2)))
    (let-temporarily (((v 1) 32))
      (v 1))))

(define fs10
  (let ((val 0))
    (let ((fs (dilambda (lambda () val) (lambda (v) (set! val v)))))
      (lambda ()
	(set! (fs) 32)
	(fs)))))

    
(define (tf)
  (do ((i 0 (+ i 1)))
      ((= i 150000))
    (fs1)
    (fs2)
    (fs3)
    (fs4)
    (fs5)
    (fs6)
    (fs7)
    (fs8)
    (fs9)
    (fs10)
    ))

(tf)


;;; -------- => --------
(define-constant (f1)
  (cond (-2 => abs)))

(define-constant (x+1 x) 
  (+ x 1))

(define-constant (f2)
  (cond (32 => x+1)))

(define* (x+y x (y 2))
  (+ x y))

(define-constant (f3 z)
  (cond ((if z 1 3) => x+y)))

(define-constant (f4)
  (cond ((random 1) => "asdf")))

(define (xs)
  (values 1 2 3))

(define-constant (f5)
  (do ((i 0 (+ i 1))) ((xs) => +)))

(define-constant (f6 x)
  (case x ((1) 2) (else => abs)))

(define (ftest)
  (unless (= (f1) 2) (format *stderr* "f1 got ~S~%" (f1)))
  (unless (= (f2) 33) (format *stderr* "f2 got ~S~%" (f2)))
  (unless (= (f3 #t) 3) (format *stderr* "(f3 #t) got ~S~%" (f3 #t)))
  (unless (= (f3 #f) 5) (format *stderr* "(f3 #f) got ~S~%" (f3 #f)))
  (unless (char=? (f4) #\a) (format *stderr* "(f4) got ~S~%" (f4)))
  (unless (= (f5) 6) (format *stderr* "(f5) got ~S~%" (f5)))
  (unless (= (f6 -2) 2) (format *stderr* "(f6 -2) got ~S~%" (f6 -2)))

  (do ((i 0 (+ i 1)))
      ((= i size))
    (f1)
    (f2)
    (f3 #t)
    (f4)
    (f5)
    (f6 -2)))

(ftest)
(wtest)


;;; -------- typers --------
(let ()
  (define (10-or-12? val)
    (and (integer? val) ; hmmm -- this is faster than (memv val '(10 12))
	 (or (= val 10) 
	     (= val 12))))
  
  (define (symbol-or-integer? key)
    (or (symbol? key)
	(integer? key)))
  
  (define (a? k1 k2) (eq? k1 k2))
  (define (a->int key) 0)
  
  (define h0 (make-hash-table 8 #f (cons #t integer?)))
  (define h1 (make-hash-table 8 #f (cons #t 10-or-12?)))
  (define h2 (make-hash-table 8 #f (cons symbol? integer?)))
  (define h3 (make-hash-table 8 #f (cons symbol-or-integer? 10-or-12?)))
  (define h4 (make-hash-table 8 (cons a? a->int) (cons symbol? integer?)))
  (define h5 (make-hash-table 8 char=? (cons char? integer?)))
  
  (define v0 (make-vector 3 'x symbol?))
  (define v1 (make-vector 3 10 10-or-12?))
  
  (define e0 (let ((a 10))
	       (set! (setter 'a) integer?)
	       (curlet)))
  
  (define e1 (let ((a 10))
	       (set! (setter 'a) (lambda (s v)
				   (if (10-or-12? v)
				       v
				       (error 'wrong-type-arg "~S is not 10 or 12?" v))))
	       (curlet)))
  
  (define (test tests)
    (do ((i 0 (+ i 1)))
	((= i tests))
      (set! (h0 'a) 123)
      (set! (h1 'a) 10)
      (set! (h2 'a) 123)
      (set! (h3 'a) 12)
      (set! (h4 'a) 0)
      (set! (h5 #\a) 123)
      (set! (v0 0) 'a)
      (set! (v1 0) 12)
      (set! (e0 'a) 12)
      (set! (e1 'a) 12)))
  
  (test 100000))


;;; typer optimization tests

(define typer-size 1000000)

;; -------- int-vector
(define (iv1) ; 77.9 -> 59.0 (no make-integer)
  (let ((v (make-vector typer-size 1 integer?))
	(sum 0))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (vector-ref v i))))
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (iv2) ; 77.9 -> 59.0 (no make-integer)
  (let ((v (make-int-vector typer-size 1))
	(sum 0))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (int-vector-ref v i)))) ; but TODO: this still makes integers (not safe stepper?! in opt_dotimes)
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (iv3) ; 201.6 -- twice as slow as h1 because mark_vector is slow, 196.2 if new mark_vector_1
  (let ((v (make-vector typer-size 1))
	(sum 0))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (vector-ref v i))))
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (ih1) ; 112.7 -- fails i_7pi_ok
  (let ((h (make-hash-table 8 #f (cons symbol? integer?)))
	(sum 0))
    (hash-table-set! h 'a 1)
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (hash-table-ref h 'a)))) ; this is independent of i...
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (iv4) ; 29.6
  (let ((v (make-vector typer-size 1 integer?))) ; this creates an int-vector! so iv4 == iv7
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (vector-ref v i) 0)
	  (display "oops")))))

(define (iv5) ; 29.6
  (let ((v (make-int-vector typer-size 1)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (int-vector-ref v i) 0)
	  (display "oops")))))

(define (iv6) ; 44.6
  (let ((v (make-vector typer-size 1)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (vector-ref v i) 0)
	  (display "oops")))))

(define (iv7) ; 29.6
  (let ((v (make-int-vector typer-size 1)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (vector-ref v i) 0) ; opt_i_7pi_ss + opt_b_ii_fc_eq, opt_dotimes and opt_i_pi_ss_ivref which is direct
	  (display "oops")))))


;; -------- float-vector
(define (fv1) ; 113.6 -> 97.2 via d_7pi_ok -> 85.2
  (let ((v (make-vector typer-size 1.0 float?))
	(sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (vector-ref v i))))
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (fv2) ; 93.2 -> 85.2 opt_float_any_nv removed -> 66 (no make-integer)
  (let ((v (make-float-vector typer-size 1.0))
	(sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (float-vector-ref v i))))  ; float_vector_ref_d_pi_direct, but TODO: this still makes integers (not safe stepper?! in opt_dotimes)
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (fv3) ; 197.8 192.3
  (let ((v (make-vector typer-size 1.0))
	(sum 0.0))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (vector-ref v i))))
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (fh1) ; 108.9
  (let ((h (make-hash-table 8 #f (cons symbol? float?)))
	(sum 0.0))
    (hash-table-set! h 'a 1.0)
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (hash-table-ref h 'a)))) ; this is independent of i...
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (fv4) ; 77.8 -> 40.75 via d_7pi_ok
  (let ((v (make-vector typer-size 1.0 float?))) ; this creates a float-vector! so v4 == v7
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (vector-ref v i) 0.0)
	  (display "oops")))))

(define (fv5) ; 40.75
  (let ((v (make-float-vector typer-size 1.0)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (float-vector-ref v i) 0.0) ; opt_d_7pi_ss_fvref_direct + num_eq_b_dd
	  (display "oops")))))

(define (fv6) ; 57.75
  (let ((v (make-vector typer-size 1.0)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (vector-ref v i) 0.0)
	  (display "oops")))))

(define (fv7) ; 77.8 -> 40.75 via d_7pi_ok
  (let ((v (make-float-vector typer-size 1.0)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (vector-ref v i) 0.0)
	  (display "oops")))))


;; -------- byte-vector
(define (bv1) ; 77.9 -> 58.7 (no make-integer)
  (let ((v (make-vector typer-size 1 byte?))
	(sum 0))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (vector-ref v i))))
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (bv2) ; 77.9 -> 58.7 (no make-integer)
  (let ((v (make-byte-vector typer-size 1))
	(sum 0))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (byte-vector-ref v i))))
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (bv3) ; 201.9
  (let ((v (make-vector typer-size 1))
	(sum 0))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (vector-ref v i))))
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (bh1) ; 112.9
  (let ((h (make-hash-table 8 #f (cons symbol? byte?)))
	(sum 0))
    (hash-table-set! h 'a 1)
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (set! sum (+ sum (hash-table-ref h 'a)))) ; this is independent of i...
    (unless (= sum typer-size) (format *stderr* "sum: ~D~%" sum))))

(define (bv4) ; 51.6 -> 29.7
  (let ((v (make-vector typer-size 1 byte?)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (vector-ref v i) 0)
	  (display "oops")))))

(define (bv5) ; 72.6 -> 29.7 opt_arg_type
  (let ((v (make-byte-vector typer-size 1)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (byte-vector-ref v i) 0)
	  (display "oops")))))

(define (bv6) ; 44.8
  (let ((v (make-vector typer-size 1)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (vector-ref v i) 0)
	  (display "oops")))))

(define (bv7) ; 51.6 -> 29.7
  (let ((v (make-byte-vector typer-size 1)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (= (vector-ref v i) 0)
	  (display "oops")))))

(define (bv8) ; 53.6
  (let ((v (make-byte-vector typer-size 1))
	(typer-size/2 (/ typer-size 2)))
    (do ((i (- typer-size/2) (+ i 1)))
	((= i typer-size/2))
      (if (= (vector-ref v (+ i typer-size/2)) 0)
	  (display "oops")))))

(define (bv9) ; 68.9
  (let ((v (make-vector typer-size 1))
	(typer-size/2 (/ typer-size 2)))
    (set! (vector-typer v) integer?)
    (do ((i (- typer-size/2) (+ i 1)))
	((= i typer-size/2))
      (if (= (vector-ref v (+ i typer-size/2)) 0)
	  (display "oops")))))


;; -------- string?

(define (sv1) ; 41.6 -> 31.6, opt_p_c -> opt_b_pp_fc_char_eq
  (let ((v (make-string typer-size #\a)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (char=? (string-ref v i) #\b) ; opt_b_pp_ff_char_eq + opt_p_pi_ss_sref_direct in opt_dotimes
	  (display "oops")))))

(define (sv2) ; 74.9 [uses opt_b_pp_fc_char_eq, string_ref_p_pp+string_ref_1 (typer ignored?), opt_p_pi_sc for (unchanging) vector-ref]
  (let ((v (make-vector 1 (make-string typer-size #\a) string?)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (char=? (string-ref (vector-ref v 0) i) #\b)
	  (display "oops")))))

(define (sv3) ; 58.0 via opt_b_pp_ff opt_p_pi_ss_vref_direct string_eq_b_unchecked [so it sees the typer?] -> 53.0 (fc case)
  (let ((v (make-vector typer-size "a" string?)))
    (do ((i 0 (+ i 1)))
	((= i typer-size))
      (if (string=? (vector-ref v i) "b")
	  (display "oops")))))

(define (try-all) ; 2046  1924(opt_dotimes)
  (iv1) (iv2) (iv3) (iv4) (iv5) (iv6) (iv7)
  (ih1)
  (fv1) (fv2) (fv3) (fv4) (fv5) (fv6) (fv7)
  (fh1)
  (bv1) (bv2) (bv3) (bv4) (bv5) (bv6) (bv7) (bv8) (bv9)
  (bh1)
  (sv1) (sv2) (sv3)
  )

(try-all)



;;; -------- built-ins via #_ --------

(define (u0)
  (do ((i 0 (+ i 1)))
      ((= i 100000) (#_list))
    (#_list)))

(unless (null? (u0)) (format *stderr* "u0: ~S~%" (u0)))

(define (u1)
  (do ((i 0 (+ i 1)))
      ((= i 1000000) (#_length "asdfghjklijk"))
    (#_length "asdfghjklijk")))

(unless (eqv? (u1) 12) (format *stderr* "u1: ~S~%" (u1)))

(define (u2)
  (let ((str "asdfghjklijk"))
    (do ((i 0 (+ i 1)))
	((= i 100000) (#_char-position #\h str))
      (#_char-position #\h str))))

(unless (eqv? (u2) 5) (format *stderr* "u2: ~S~%" (u2)))

(define (u3)
  (do ((i 0 (+ i 1)))
      ((= i 1000000) (#_+ i (* -2 i) i))
    (#_+ i (* -2 i) i)))

(unless (eqv? (u3) 0) (format *stderr* "u3: ~S~%" (u3)))


;;; -------- methods --------

(unless (provided? 'pure-s7)

  (define (m5 str)
    (let ((L (openlet (inlet :length (lambda (s) (+ 2 (#_string-length str)))))))
      (do ((i 0 (+ i 1)))
	  ((= i 1000000) (length L))
	(length L))))
  
  (unless (eqv? (m5 "asdfghjklijk") 14) (format *stderr* "m5: ~S~%" (m5 "asdfghjklijk")))
  
  (define (m6 str)
    (let ((L (openlet (inlet :str str :length (lambda (s) (+ 2 (#_string-length s)))))))
      (do ((i 0 (+ i 1)))
	  ((= i 1000000) (with-let L (length str)))
	(with-let L
	  (length str)))))
  
  (unless (eqv? (m6 "asdfghjklijk") 14) (format *stderr* "m6: ~S~%" (m6 "asdfghjklijk"))))

(define (m7)
  (let ((L (openlet (inlet :+ (lambda (x y) (#_+ x y 1))))))
    (do ((i 0 (+ i 1)))
	((= i 500000) ((L :+) 2 3))
      ((L :+) 2 3))))

(unless (eqv? (m7) 6) (format *stderr* "m7: ~S~%" (m7)))

(define (m8)
  (let ((L (openlet (inlet :+ (lambda args (apply #_+ 1 args))))))
    (do ((i 0 (+ i 1)))
	((= i 500000) (with-let L (+ 2 3)))
      (with-let L (+ 2 3)))))

(unless (eqv? (m8) 6) (format *stderr* "m8: ~S~%" (m8)))


;;; -------- unlet --------
;;; incrementally set all globals to 42 -- check that unlet exprs return the same results

(when (zero? (*s7* 'profile))
  (let* ((syms (symbol-table))
	 (num-syms (length syms)))
    
    (define (unlet-test i)
      (with-let (unlet)
	(catch #t
	  (lambda ()
	    (eval `(define ,(syms i) 42))
	    (when (procedure? (symbol->value (syms i) (rootlet)))
	      (with-let (unlet)
		(eval `(set! ,(syms i) 42) (rootlet)))))
	  (lambda (type info)
	    #f))))

    (do ((i 0 (#_+ i 1))) ; "do" is not a procedure (see above) so it's not in danger here
	((#_= i num-syms))
      (unlet-test i))))


(#_exit) ; we just clobbered exit above
