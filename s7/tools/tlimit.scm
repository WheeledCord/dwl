;; timing test for multi-parameter funcs and so on

(define size 10000) ; tried also 100k and 1M -- compute time is in format_to_port_1
;(define size 1000000)
;;; 10k:  0.098u 0.023s
;;; 100k: 1.657u 0.216s
;;; 1M:  52.178u 1.935s

(define time-column 32)

(define (report-time name value output-string)
  ;; (format *stderr* "~D ~A output: ~NT~,4G~%" size name time-column (- (*s7* 'cpu-time) start))
  ;; (set! start (*s7* 'cpu-time))
  
  (unless (equal? (eval-string output-string) value)
    (format *stderr* "~D ~A: ~S~%" size name (eval-string output-string)))
  
  (format *stderr* "~D ~A: ~NT~,4G~%" size name time-column (- (*s7* 'cpu-time) start))
  (set! start (*s7* 'cpu-time)))


(define start (*s7* 'cpu-time))


;; -------- N let vars --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~% (+ f_0 f_~D))~%" (- size 1))))))
  
  (report-time "let vars" 2 str))


;; -------- N let* vars --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let* (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~% (+ f_0 f_~D))~%" (- size 1))))))
  
  (report-time "let* vars" 2 str))


;; -------- N letrec vars --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(letrec (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~% (+ f_0 f_~D))~%" (- size 1))))))
  
  (report-time "letrec vars" 2 str))


;; -------- N letrec* vars --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(letrec* (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~% (+ f_0 f_~D))~%" (- size 1))))))
  
  (report-time "letrec* vars" 2 str))


;; -------- N do vars --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(do (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1 (+ f_~D 1))~%" i i))
	      (format p "   ) ((= f_0 1) (+ f_0 f_~D)))~%" (- size 1))))))
  
  (report-time "do vars" 2 str))


;; -------- N let vars added --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%  (+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))~%")))))
  
  (report-time "let vars added" size str))


;; -------- N let* vars added --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let* (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%  (+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))~%")))))
  
  (report-time "let* vars added" size str))


;; -------- N let vars = --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%  (= ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))~%")))))
  
  (report-time "let vars =" #t str))


;; -------- N let vars max --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%  (max ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))~%")))))
  
  (report-time "let vars max" 1 str))


;; -------- N let vars or --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D #f)~%" i))
	      (format p "   )~%  (or ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))~%")))))
  
  (report-time "let vars or" #f str))


;; -------- N let vars add values1 --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%  (+ (values ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ")))~%")))))
  
  (report-time "let vars add values1" size str))


;; -------- N let vars add values2 --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(+ (let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%  (values ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ")))~%")))))
  
  (report-time "let vars add values2" size str))


;; -------- N let vars nested add --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%  (+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D (+ " i))
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p ")"))
	      (format p "))~%")))))
  
  (report-time "let vars nested add" size str))


;; -------- N let vars lambda add --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%  ((lambda args (apply + args)) ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))~%")))))
  
  (report-time "let vars lambda add" size str))


;; -------- N inlet vars add --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(with-let (inlet ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "'f_~D 1 " i))
	      (format p "   )~%  (+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))~%")))))
  
  (report-time "inlet vars add" size str))


;; -------- N let vars string --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D #\\a)~%" i))
	      (format p "   )~%  (string ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))~%")))))
  
  (report-time "let vars string" (make-string size #\a) str))


;; -------- N let vars mapped --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D -1)~%" i))
	      (format p "   )~% (car (map symbol? '(")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))))~%")))))
  
  (report-time "let vars mapped" #t str))


;; -------- N let vars sorted --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D ~D)~%" i i))
	      (format p "   )~% (vector-ref (sort! (vector ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ") <) 0))~%")))))
  
  (report-time "let vars sorted" 0 str))


;; -------- call/cc return values --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(+ (call/cc (lambda (return) (return ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "~D " i))
	      (format p "))))")))))
  
  (report-time "call/cc return values" (* (/ size 2) (- size 1)) str))


;; -------- lambda args --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "((lambda (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ") (+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ")) ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "~D " i))
	      (format p ")")))))
  
  (report-time "lambda args" (* (/ size 2) (- size 1)) str))


;; -------- lambda* args --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "((lambda* (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ") (+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ")) ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "~D " i))
	      (format p ")")))))
  
  (report-time "lambda* args" (* (/ size 2) (- size 1)) str))


;; -------- lambda* args + defaults --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "((lambda* (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "(f_~D ~D) " i i))
	      (format p ") (+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ")))")))))
  
  (report-time "lambda* args + defaults" (* (/ size 2) (- size 1)) str))


;; -------- named let args --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let loop (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "(f_~D ~D) " i i))
	      (format p ") (+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ")) ")))))
  
  (report-time "named let args" (* (/ size 2) (- size 1)) str))


;; -------- named let* args --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let* loop (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "(f_~D ~D) " i i))
	      (format p ") (+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ")) ")))))
  
  (report-time "named let* args" (* (/ size 2) (- size 1)) str))


;; -------- let-temporarily args --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "(f_~D 0)" i))
	      (format p ") (let-temporarily (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "(f_~D ~D)" i i))
	      (format p ") (+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p ")))")))))
  
  (report-time "let-temporarily args" (* (/ size 2) (- size 1)) str))


;; -------- memq --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(memq 'f_~D '(" (- size 1)) ; not ints here -- not eq?!
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))")))))
  
  (report-time "memq" (list (symbol "f_" (number->string (- size 1)))) str))


;; -------- assq --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(assq 'f_~D '(" (- size 1))
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "(f_~D ~D) " i (* i 2)))
	      (format p "))")))))
  
  (report-time "assq" (list (symbol "f_" (number->string (- size 1))) (* 2 (- size 1))) str))


;; -------- read-time vector --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(apply + (vector->list #(")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "~D " i))
	      (format p ")))")))))
  
  (report-time "read-time vector" (* (/ size 2) (- size 1)) str))


;; -------- N lets nested --------
(let-temporarily ((size (min size (min size 1000))))
  (let ((str (call-with-output-string
	      (lambda (p)
		(do ((i 0 (+ i 1)))
		    ((= i size))
		  (format p "(let ((f_~D ~D)) " i i))
		(format p "(+ ")
		(do ((i 0 (+ i 1)))
		    ((= i size))
		  (format p "f_~D " i))
		(do ((i 0 (+ i 1)))
		    ((= i size))
		  (format p ")"))
		(format p ")")))))
    
    (report-time "lets nested" (* (/ size 2) (- size 1)) str)))


;; -------- N let vars+set+add --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D ~D)~%" i i))
	      (format p "   )~%")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (set! f_~D (* 2 f_~D))~%" i i))
	      (format p "(+ ")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "f_~D " i))
	      (format p "))")))))
  
  (report-time "let vars+set+add" (* size (- size 1)) str))


;; -------- N lambdas nested --------
(let-temporarily ((size (min size (min size 1000))))
  (let ((str (call-with-output-string
	      (lambda (p)
		(do ((i 0 (+ i 1)))
		    ((= i size))
		  (format p "("))
		(do ((i 0 (+ i 1)))
		    ((= i size))
		  (format p "(lambda (f_~D)~%" i))
		(format p "(+ ")
		(do ((i 0 (+ i 1)))
		    ((= i size))
		  (format p "f_~D " i))
		(do ((i 0 (+ i 1)))
		    ((= i (+ size 1)))
		  (format p ")"))
		(do ((i 0 (+ i 1)))
		    ((= i size))
		  (format p " ~D)" i))))))
    
    (report-time "lambdas nested" (* (/ size 2) (- size 1)) str)))


;; these are aimed at the optimizer
;; -------- N vars + 1-arg func --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(begin (define (f) (let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%")
	      (do ((i 0 (+ i 1)))
		  ((not (< i size)))
		(format p "(+ (abs f_~D) (abs f_~D))~%" i (- size i 1)))
	      (format p ")) (f))~%")))))
  
  (report-time "vars + 1-arg func" 2 str))


;; -------- N vars + 2-arg func --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(begin (define (f) (let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%")
	      (do ((i 0 (+ i 1)))
		  ((not (< i size)))
		(format p "(ash f_~D f_~D)~%" i (- size i 1)))
	      (format p ")) (f))~%")))))
  
  (report-time "vars + 2-arg func" 2 str))


;; -------- N vars + 3-arg func --------
(let ((str (call-with-output-string
	    (lambda (p)
	      (format p "(begin (define (f) (let (")
	      (do ((i 0 (+ i 1)))
		  ((= i size))
		(format p "  (f_~D 1)~%" i))
	      (format p "   )~%")
	      (do ((i 0 (+ i 1)))
		  ((not (< i size)))
		(format p "(+ f_~D f_~D 1)~%" i (- size i 1)))
	      (format p ")) (f))~%")))))
  
  (report-time "vars + 3-arg func" 3 str))

(exit)
