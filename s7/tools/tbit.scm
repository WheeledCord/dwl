; tbit.scm: bit op timing tests

(define size 1000000)
(define size/5 (/ size 5))
(define size/10 (/ size 10))


(define (make-bit-vector n)
  (make-int-vector (ceiling (/ n 63))))

(define (bit-vector-ref v n)
  (logbit? (int-vector-ref v (quotient n 63)) (remainder n 63)))

(define (bit-vector-set! v n t-or-f)
  (int-vector-set! v (quotient n 63)
		   (let ((cur (int-vector-ref v (quotient n 63)))
			 (bit (ash 1 (remainder n 63))))
		     (if t-or-f
			 (logior cur bit)
			 (logand cur (lognot bit))))))

(let ((bv (make-bit-vector 128)))
  (if (bit-vector-ref bv 72)
      (format *stderr* "default #f: ~A~%" (bit-vector-ref bv 72)))
  (bit-vector-set! bv 72 #t)
  (if (not (bit-vector-ref bv 72))
      (format *stderr* "set: ~A~%" (bit-vector-ref bv 72)))
  (bit-vector-set! bv 72 #f)
  (if (bit-vector-ref bv 72)
      (format *stderr* "clear #f: ~A~%" (bit-vector-ref bv 72))))

(define (bit-test1)
  (let ((bv (make-bit-vector 100)))
    (do ((i 0 (+ i 1)))
	((= i 100))
      (bit-vector-set! bv i (odd? i)))
    (do ((i 0 (+ i 1))
	 (loc (random 100) (random 100)))
	((= i size))
      (unless (eq? (bit-vector-ref bv loc) (odd? loc))
	(display 'oops)))))

;; (bit-test1) ; 543, eval 191, fx_num_eq_us 52, fx_c_s_opsiq_direct 37, fx_c_aa 36, int_vector_ref_p_pp 32, fx_random_i 27


(define (bit-reverse int)
  ;; from "Hacker's Delight" Henry Warren p101, but 64 bit
  (let ((x int))
    (set! x (logior (ash (logand x #x5555555555555555) 1)
		    (ash (logand x #xAAAAAAAAAAAAAAAA) -1)))
    (set! x (logior (ash (logand x #x3333333333333333) 2)
		    (ash (logand x #xCCCCCCCCCCCCCCCC) -2)))
    (set! x (logior (ash (logand x #x0F0F0F0F0F0F0F0F) 4)
		    (ash (logand x #xF0F0F0F0F0F0F0F0) -4)))
    (set! x (logior (ash (logand x #x00FF00FF00FF00FF) 8)
		    (ash (logand x #xFF00FF00FF00FF00) -8)))
    (set! x (logior (ash (logand x #x0000FFFF0000FFFF) 16)
		    (ash (logand x #xFFFF0000FFFF0000) -16)))
    (logior (ash (logand x #x00000000FFFFFFFF) 32)
	    (ash (logand x #xFFFFFFFF00000000) -32))))

;; (let ((x (ash (bit-reverse #x01234566) -32))) (test x 1721943168)) ; #x66a2c480

(define (bit-test2)
  (do ((i 0 (+ i 1)))
      ((= i size/5))
    (bit-reverse #x63084210))) ; #x84210c6

;; (bit-test2) ; 499, g_logand 96, fx_c_opscq_c 92, g_ash 86, eval 83, g_logior 49
               ; 480, g_ash_ii 74


(define 2^n?
  (let ((+documentation+ "(2^n? x) returns #t if x is a power of 2"))
    (lambda (x)
      (and (integer? x)
	   (not (zero? x))
	   (zero? (logand x (- x 1)))))))

(define (2^n-1? x)
  (and (integer? x)
       (zero? (logand x (+ x 1)))))

(define (2-ruler n) ; translated from CLOCC cllib/math.lisp, ruler
  ;; The exponent of the largest power of 2 which divides the given number.
  (- (integer-length (logand n (- n))) 1))

(define (lognand . ints)  ; viewed as (not (and ...))
  (lognot (apply logand ints)))

(define (lognor . ints)
  (lognot (apply logior ints)))

(define (logeqv . ints)
  (lognot (apply logxor (if (odd? (length ints))
			    (values -1 ints) ; Clisp does it this way
			    ints))))

(define (log-none-of . ints)  ; bits on in none of ints
  (lognot (apply logior ints)))

(define every?
  (let ((+documentation+ "(every? func sequence) returns #t if func approves of every member of sequence"))
    (lambda (f sequence)
      (call-with-exit
       (lambda (return)
	 (for-each (lambda (arg) (if (not (f arg)) (return #f))) sequence)
	 #t)))))

(define (log-n-of n . ints)   ; return the bits on in exactly n of ints
  (cond ((not (integer? n))
	 (error 'wrong-type-arg "log-n-of first argument, ~A, should be an integer" n))
	((not (every? integer? ints))
	 (error 'wrong-type-arg "log-n-of ints arguments, ~A, should all be integers" ints))
	((negative? n)
	 (error 'out-of-range "log-n-of first argument should be positive: ~A" n))
	(else
	 (let ((len (length ints)))
	   (cond ((= len 0) (if (= n 0) -1 0))
		 ((= n 0)   (lognot (apply logior ints)))
		 ((= n len) (apply logand ints))
		 ((> n len) 0)
		 (#t
		  (do ((1s 0)
		       (prev ints)
		       (nxt (cdr ints))
		       (ln (- len 1))
		       (nn (- n 1))
		       (i 0 (+ i 1)))
		      ((= i len) 1s)
		    (let ((cur (ints i)))
		      (if (= i 0)
			  (set! 1s (logior 1s (logand cur (apply log-n-of nn nxt))))
			  (let ((mid (cdr prev)))
			    (set! (cdr prev) (if (= i ln) () (cdr mid)))
			    (set! 1s (logior 1s (logand cur (apply log-n-of nn ints))))
			    (set! (cdr prev) mid)
			    (set! prev mid)))))))))))

(define (bit-test3)
  (do ((i 0 (+ i 1)))
      ((= i size/5))
    (2^n? i)
    (2^n-1? i)
    (2-ruler i)
    (lognand i (- i))
    (lognor i (- i))
    (logeqv i (+ i 1))))

;; (bit-test3) ; 442, eval 128, op_any_closure_sym 48, g_logand 30
               ; 431, g_logand_2 14

(define (bit-test4)
  (do ((i 0 (+ i 1)))
      ((= i size/10))
    (log-n-of 1 i (+ i 1))))

;; (bit-test4) ; 817, eval 386, gc 63, op_do_init_1 46, fx_s 30
               ; 811, g_logand_2


(define (byte siz pos) ;; -> cache size, position and mask.
  (list siz pos (ash (- (ash 1 siz) 1) pos)))

(define (ldb bytespec integer)
  (ash (logand integer (caddr bytespec))
       (- (cadr bytespec))))

(define (dpb integer bytespec into)
  (logior (ash (logand integer (- (ash 1 (car bytespec)) 1)) (cadr bytespec))
	  (logand into (lognot (caddr bytespec)))))

(define (bit-test5)
  (do ((i 0 (+ i 1)))
      ((= i size/5))
    (dpb (ldb (byte 8 0) #x123) (byte 8 1) #x100)))

;; (bit-test5) ; 321, eval 48, g_ash 45
               ; 308, g_logand_2


;; from slib
(define bitwise-bit-count
  (letrec ((logcnt (lambda (n tot)
		     (if (zero? n)
			 tot
			 (logcnt (quotient n 16)
				 (+ (vector-ref #(0 1 1 2 1 2 2 3 1 2 2 3 2 3 3 4) (modulo n 16)) tot)))))) ; int-vector slower?
    (lambda (n)
      (cond ((negative? n) (lognot (logcnt (lognot n) 0)))
	    ((positive? n) (logcnt n 0))
	    (else 0)))))

(define (pop-count n) ; logcount in slib I think
  (cond ((negative? n) (bitwise-bit-count (lognot n)))
	(else (bitwise-bit-count n))))

(define (bit-test6)
  (do ((i 0 (+ i 1)))
      ((= i size/5))
    (pop-count (logxor i (ash i 1)))))

;; (bit-test6) ; 304, eval 42, modulo_p_pp 37


;; from sbcl/contrib/sb-rotate-byte
(define (rotate-byte count bytespec integer)  ; logrot?
  (let* ((size (car bytespec))
	 (count (- count (* (round (/ count size)) size)))
	 (mask (ash (- (ash 1 size) 1) (cdr bytespec)))
	 (field (logand mask integer)))
    (logior (logand integer (lognot mask))
	    (logand mask
		    (logior (ash field count)
			    (ash field ((if (positive? count) - +) count size)))))))

(define (bit-test7)
  (let ((b (cons 16 0)))
    (do ((i 0 (+ i 1)))
	((= i size/5))
      (rotate-byte i b -3))))

(bit-test7) ; 405, eval 93, gc 35, op_let_star_na 32, g_ash 29
               ; 387. g_logand_2


(define (bit-test)
  (bit-test1)
  (bit-test2)
  (bit-test3)
  (bit-test4)
  (bit-test5)
  (bit-test6)
  (bit-test7))

;(bit-test)
