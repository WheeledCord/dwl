(set! (*s7* 'heap-size) 512000)

(let ()
  (define size 1000000)

  (let ((old-print (*s7* 'print-length))) ; opt_starlet_set and opt_starlet_set_i -- these could be optimized further to avoid starlet_set_1
    (define (f100)
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(set! (*s7* 'print-length) 32)))
    (f100)
    (define (f101 x)
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(set! (*s7* 'print-length) (abs x))))
    (f101 -31)
    (set! (*s7* 'print-length) old-print))

  (define-constant (f1)
    (let-temporarily (((*s7* 'openlets) #f))
      (*s7* 'openlets)))
  (define (f11)
    (do ((i 0 (+ i 1)))
	((= i size))
      (f1)))
  
  (f11) ; 169 eval+starlet, no args so f1->body? let_temp_s7_openlets
        ; 146 if no closure
        ; 307 if print-length, starlet_set_1


  (define (f12)
    (let ((obj -1))
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(abs obj))))
  (f12) ; 18: 10-20 times faster than f1, opt_dotimes -> opt_i_i_s_abs
  

  (define (f14)
    (let ((obj -1))
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(magnitude obj))))
  (f14) ; 38
  
  
  (define-constant (f2 x)
    (set! (*s7* 'safety) 1)
    (+ x 1)
    (set! (*s7* 'safety) 0))
  
  (define (f21)
    (do ((i 0 (+ i 1)))
	((= i size))
      (f2 i)))
  
  (f21) ; 707 -> 386 -> 357: 336 eval+starlet_set+g_add_x1, avoid starlet_set if safety etc? (much overhead)
  

  (define-constant (f3 x)
    (+ (*s7* 'safety) (*s7* 'print-length)))
  
  (define (f31)
    (do ((i 0 (+ i 1)))
	((= i size))
      (f3 i)))

  (f31) ; 211 -> 180 (print-length): 107 fx_add_aa+fx_safe_closure_t_a+fx_implicit_starlet_print_length|safety+op_safe_dotimes (arg ignored)


  (define (f15)
    (do ((j 0)
	 (i 0 (+ i 1)))
	((= i size))
      (let-ref *s7* 'print-length)))
  (f15)
  ;; 317 -> 210 sc->starlet_ref


  (define (f17)
    (do ((j 0)
	 (i 0 (+ i 1)))
	((= i size))
      (let-set! *s7* 'print-length 32)))
  (f17)
  ;; 354 -> 240 starlet_set


  (define (f18)
    (do ((i 0 (+ i 1)))
	((= i size))
      (let-ref (rootlet) 'abs)))
  (f18)
  ;; 14


  (define (f6)
    (let ((obj (openlet (inlet 'value -1 
			       'abs (lambda (x)
				      (let-temporarily (((*s7* 'openlets) #f))
					(abs (x 'value))))))))
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(abs obj))))

  (f6) ; 628! -> 425: 396 eval+find_and_apply_method+g_abs


  (define (f7)
    (let ((obj (openlet (inlet 'value -1 
			       'abs (lambda (x) 
				      (magnitude (x 'value)))))))
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(abs obj)))) ; eval -> apply_c_function -> magnitude_p_p -> s7_let_ref + method_or_bust etc [50]
  (f7) ; 360 -> 342 [find_and_apply_method/apply_method_closure+magnitude_p_p+g_abs]
  
  
  (define (f13)
    (let ((obj (openlet (let ((value -1))
			  (define (abs x) (magnitude value))
			  (curlet)))))
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(abs obj)))) ; eval -> apply_c_function -> magnitude_p_p -> method_or_bust etc g_abs find_method_with_let
  (f13) ; not much faster 314
  
  
  (define (f15)
    (let ((obj (openlet (sublet (inlet 'abs (lambda (x) (magnitude (x 'value))))
			  'value -1))))
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(abs obj)))) ; eval -> apply_c_function -> magnitude_p_p -> s7_let_ref + method_or_bust etc
  (f15) ; 360
  
  
  (define-constant (f8 x)
    (if (let? x)
	((let-ref x 'f82) x)
	(+ x 1)))
  
  (define (f81)
    (let ((obj (openlet (inlet 'value -1 
			       'f82 (lambda (x)
				     (+ (x 'value) 1))))))
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(f8 obj))))
  
  (f81) ; 505
  
  
  (define f9 (dilambda
	      (lambda (x)
		(if (let? x)
		    ((let-ref x 'f9) x)
		    (+ x 1)))
	      (lambda (x y)
		(if (let? x)
		    ((let-ref x 'set-f9) x y)
		    'oops))))
  
  (define (f91)
    (let ((obj (openlet (inlet 'value -1 
			       'f9 (lambda (x)
				     (+ (x 'value) 1))
			       'set-f9 (lambda (x y)
					 (set! (x 'value) y))))))
      (display (f9 obj)) (newline) ; 0
      (set! (f9 obj) 32)
      (display (f9 obj)) (newline) ; 32
      
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(set! (f9 obj) i))))
  
  (f91) ; 1142
  
  
  (define (f10)
    (let ((obj (openlet (inlet 'value -1 
			       'abs (lambda (x) 
				      (magnitude (x 'value)))
			       'set-abs (lambda (x y)
					  (set! (x 'value) y))))))
      (set! (setter abs)
	    (lambda (x y)
	      (if (let? x)
		  ((let-ref x 'set-abs) x y)
		  'oops)))
      (display (abs obj)) (newline) ; 1
      (set! (abs obj) 32)
      (display (abs obj)) (newline) ; 32
      
      (do ((i 0 (+ i 1)))
	  ((= i size))
	(set! (abs obj) i))))
  
  (f10) ; 1142
)

(set! (setter abs) #f)

(exit)
