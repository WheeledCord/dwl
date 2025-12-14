;;; r7rs compatibility

(require libc.scm)
(provide 'r7rs.scm)


(define (vector-map p . args) (apply vector (apply map p args)))
(define (string-map p . args) (apply string (apply map p args)))
(define vector-for-each for-each)
(define string-for-each for-each)

(define* (vector->string v (start 0) end)
  (let ((stop (or end (length v))))
    (copy v (make-string (- stop start)) start stop)))

(define* (string->vector s (start 0) end)
  (let ((stop (or end (length s))))
    (copy s (make-vector (- stop start)) start stop)))

(define list-copy copy)
(define vector-copy string->vector)
(define string-copy substring)

(define* (vector-copy! dest at src (start 0) end) ; end is exclusive
  (if (not at)
      (copy dest)
      (if (not src)
	  (copy (subvector dest at))
	  (if (integer? src) ; good lord, who dreamed up this nonsense?
	      (copy (subvector dest at src))
	      (let ((len (or end (length src))))
		(if (or (not (eq? dest src))
			(<= at start))
		    (do ((i at (+ i 1))
			 (k start (+ k 1)))
			((= k len) dest)
		      (set! (dest i) (src k)))
		    (do ((i (- (+ at len) start 1) (- i 1))
			 (k (- len 1) (- k 1)))
			((< k start) dest)
		      (set! (dest i) (src k)))))))))
(define string-copy! vector-copy!)
(define bytevector byte-vector)
(define bytevector? byte-vector?)
(define make-bytevector make-byte-vector)
(define bytevector-ref byte-vector-ref)
(define bytevector-set! byte-vector-set!)
(define bytevector-copy! vector-copy!)
(define (bytevector->list bv) (copy bv (make-list (length bv))))

(define (boolean=? . args)
  (or (null? args)
      (and (boolean? (car args))
	   (let loop ((obj (car args)) (lst (cdr args)))
	     (or (null? lst)
		 (and (eq? obj (car lst))
		      (loop obj (cdr lst))))))))

(define (symbol=? . args)
  (or (null? args)
      (and (symbol? (car args))
	   (let loop ((obj (car args)) (lst (cdr args)))
	     (or (null? lst)
		 (and (eq? obj (car lst))
		      (loop obj (cdr lst))))))))

(define char-foldcase char-downcase)
(define string-foldcase string-downcase)
;;; these and the string functions in s7 are not unicode-aware.  To get true unicode
;;;   handling of the bytes, use libutf8proc.scm, the glib functions in libxg or use cload (see xgdata.scm).
(define (digit-value c) (and (char-numeric? c) (- (char->integer c) (char->integer #\0))))


(define (finite? n) (and (number? n) (not (nan? n)) (not (infinite? n))))
(define exact-integer? integer?)
(define (exact-integer-sqrt i) (let ((sq (floor (sqrt i)))) (values sq (- i (* sq sq)))))
(define inexact exact->inexact)
(define exact inexact->exact)
(define (square x) (* x x))
(define truncate-quotient quotient)
(define truncate-remainder remainder)
(define floor-remainder modulo)
(define (floor-quotient x y) (floor (/ x y)))


(define (input-port-open? p) (not (port-closed? p)))
(define (output-port-open? p) (not (port-closed? p)))
(define (port? p) (or (input-port? p) (output-port? p)))
(define binary-port? port?)
(define textual-port? port?)
(define (close-port p) (if (input-port? p) (close-input-port p) (close-output-port p)))
(define open-binary-input-file open-input-file)
(define open-binary-output-file open-output-file)
(define (call-with-port port proc) (let ((res (proc port))) (if res (close-port port)) res))

(define bytevector-u8-ref byte-vector-ref)
(define bytevector-u8-set! byte-vector-set!)
(define bytevector-u8 (dilambda (lambda (b k) (b k)) (lambda (b k c) (set! (b k) c))))
(define bytevector-length length)
(define bytevector-copy vector-copy!)
(define bytevector-append append)

(define* (write-bytevector bv (port (current-output-port)) (start 0) end)
  (let* ((v (subvector bv start (or end (length bv))))
	 (len (length v)))
    (do ((i 0 (+ i 1)))
	((= i len))
      (write-byte (v i) port))))

(define* (read-bytevector! bv (port (current-input-port)) (start 0) end)
  (let ((lim (or end (length bv))))
    (do ((i start (+ i 1))
	 (c (read-byte port) (read-byte port)))
	((or (>= i lim)
	     (eof-object? c))
	 (if (= i start) #<eof> (- i start)))
      (set! (bv i) c))))

(define* (read-bytevector k port)
  (let* ((buf (make-byte-vector k))
	 (bytes (read-bytevector! buf port)))
    (if (eof-object? bytes)
	bytes
	(if (= k bytes)
	    buf
	    (subvector buf 0 bytes)))))

(define (get-output-bytevector port) (string->byte-vector (get-output-string port)))
(define (open-input-bytevector bv) (open-input-string (copy bv (make-string (length bv)))))
(define open-output-bytevector open-output-string)
(define read-u8 read-byte)
(define write-u8 write-byte)
(define u8-ready? char-ready?)
(define peek-u8 peek-char)

(define* (utf8->string v (start 0) end)
  (if (string? v)
      (substring v start (or end (length v)))
      (substring (byte-vector->string v) start (or end (length v)))))

(define* (string->utf8 s (start 0) end)
  (if (byte-vector? s)
      (copy (subvector s start (or end (length s))))
      (string->byte-vector (utf8->string s start end))))
(define write-simple write)

(define (eof-object) #<eof>)
(define-macro (features) '*features*) ; needs to be the local *features*


;;; I think r7rs error handling is too complicated, involving "error objects" that the spec insists are newly allocated,
;;; and (if you follow r7rs-tests.scm) are assumed to have a particular layout (they call  assq directly on the object).
;;; s7 already has a way of handling errors taken from Guile 1.8, and all the s7 C code assumes that error handling. 
;;;   The following might work, but s7 itself does not follow this code:
(define (r7rs-error msg . objs)
  (apply #_error (cons 'error (cons msg objs)) msg objs))
(define (with-exception-handler handler thunk)
  (catch #t thunk
	 (lambda (err-obj rest)
	   (handler err-obj))))
(define (raise obj) (r7rs-error (cons 'error "" obj)))
(define (raise-continuable err) (r7rs-error err))
(define (error-object? obj) (eq? (car obj) 'error))
(define error-object-message cadr)
(define error-object-irritants cddr)
(define-macro (guard results . body)
  `(catch #t
    (lambda () ,@body)
    (lambda (err-obj rest)
      (let ((,(car results) err-obj))
	(cond ,@(cdr results))))))


(define write-shared write)
(define write-simple write)

(define interaction-environment curlet)
;; for null-environment see stuff.scm

(define-macro (include . files)
  `(begin
     ,@(map (lambda (file)
	      `(load ,file (outlet (curlet))))
	    files)))
;; according to someone, this should insert the text from the included files directly into the loader input stream, perhaps:
;; (let ((old-string (port-string (current-input-port))) ; do we need to start at port-position?
;;       (new-string (let ((f (open-input-file file)))
;;                     (let ((str (port-string f))) ; since it's actually a string port?
;;                       (close-input-port f)
;;                       str))))
;;   (set! (port-string (current-input-file)) (string-append new-string old-string)))

(set! *#readers* (cons (cons #\; (lambda (s) (if (string=? s ";") (read)) (values))) *#readers*))
;; I prefer (define-expansion (comment . stuff) (values))
;;   or (format #f "~^ this is a comment ")


(define-macro (define-values vars expression)
  `(if (not (null? ',vars))
       (varlet (curlet) ((lambda ,vars (curlet)) ,expression))))

#|
(define-macro (define*-values vars expression) ; same but allows defaults for the vars
  `(if (not (null? ',vars))
       (varlet (curlet) ((lambda* ,vars (curlet)) ,expression))))

(define-macro (define-values vars . body) ; but the spec says "<expression>" here
  `(apply begin (map (lambda (var val) `(define ,var ,val)) ',vars (list (begin ,@body)))))
|#

(define-macro (let-values vars . body)
  (if (null? vars)
      `(let () ,@body)
      (if (and (pair? vars)
	       (pair? (car vars))
	       (null? (cdar vars)))
	  `((lambda ,(caar vars)
	      ,@body)
	    ,(cadar vars))
	  `(with-let (apply sublet (curlet)
			    (list ,@(map (lambda (v)
					   `((lambda ,(car v)
					       (values ,@(map (lambda (name)
								(values (symbol->keyword name) name))
							      (let args->proper-list ((args (car v)))
								(cond ((symbol? args)
								       (list args))
								      ((not (pair? args))
								       args)
								      ((pair? (car args))
								       (cons (caar args) (args->proper-list (cdr args))))
								      (else
								       (cons (car args) (args->proper-list (cdr args)))))))))
					     ,(cadr v)))
					 vars)))
	     ,@body))))

(define-macro (let*-values vals . body)
  (if (null? vals)
      `(let () ,@body)
      (let ((args ())
	    (exprs ()))
	(for-each
	 (lambda (arg+expr)
	   (set! args (cons (car arg+expr) args))
	   (set! exprs (cons (cadr arg+expr) exprs)))
	 vals)
	(let ((form `((lambda ,(car args) ,@body) ,(car exprs))))
	  (if (not (null? (cdr args)))
	      (for-each
	       (lambda (arg expr)
		 (set! form (list (list 'lambda arg form) expr)))
	       (cdr args)
	       (cdr exprs)))
	  form))))

(define-macro (case-lambda . choices)
  `(lambda args
     (cond ,@(map (lambda (choice)
		    (if (symbol? (car choice))
			`(else (apply (lambda ,(car choice) ,@(cdr choice)) args))
			(if (negative? (length (car choice)))
			    `((>= (length args) ,(abs (length (car choice))))
			      (apply (lambda ,(car choice) ,@(cdr choice)) args))
			    `((= (length args) ,(length (car choice)))
			      (apply (lambda ,(car choice) ,@(cdr choice)) args)))))
		  (if (and (pair? choices) 
			   (string? (car choices)))
		      (cdr choices) ; ignore documentation string
		      choices)))))

;; parameters
;;   s7 has no built-in parameter objects
(define* (make-parameter init converter)
  (let* ((convert (or converter (lambda (x) x)))
	 (old-values ()) ; see below -- this is part of the funclet
	 (value (convert init)))
    (lambda () value)))

(define-macro (parameterize vars . body)
  `(dynamic-wind
       (lambda ()
	 ,@(map (lambda (var)
		  `(with-let (funclet ,(car var))
		     (set! old-values (cons value old-values))
		     (set! value (convert ,(cadr var)))))
		vars))
       (lambda ()
         ,@body)
       (lambda ()
	 ,@(map (lambda (var)
		  `(with-let (funclet ,(car var))
		     (set! value (car old-values))
		     (set! old-values (cdr old-values))))
		vars))))


;; libraries?
(apply define (symbol (object->string '(scheme base))) (inlet) ()) ; ignore (scheme base)
(apply define (symbol (object->string '(scheme r5rs))) (inlet) ()) ; ignore (scheme r5rs)
(apply define (symbol (object->string '(scheme read))) (inlet) ()) ; and so on... what a pile of baloney
(apply define (symbol (object->string '(scheme write))) (inlet) ())
(apply define (symbol (object->string '(scheme time))) (inlet) ())
(apply define (symbol (object->string '(scheme file))) (inlet) ())
(apply define (symbol (object->string '(scheme cxr))) (inlet) ())
(apply define (symbol (object->string '(scheme inexact))) (inlet) ())
(apply define (symbol (object->string '(scheme char))) (inlet) ())
(apply define (symbol (object->string '(scheme complex))) (inlet) ())
(apply define (symbol (object->string '(scheme eval))) (inlet) ())
(apply define (symbol (object->string '(scheme process-context))) (inlet) ())
(apply define (symbol (object->string '(scheme case-lambda))) (inlet) ())
(apply define (symbol (object->string '(scheme lazy))) (inlet) ())
(apply define (symbol (object->string '(scheme load))) (inlet) ())
(apply define (symbol (object->string '(scheme repl))) (inlet) ())

(define-macro (define-library libname . body) ; |(lib name)| -> environment
  `(define ,(symbol (object->string libname))
     (with-let (sublet (unlet)
			 (cons 'import import)
			 (cons '*export* ())
			 (cons 'export (define-macro (,(gensym) . names)
					 `(set! *export* (append ',names *export*)))))
       ,@body
       (apply inlet
	      (map (lambda (entry)
		     (if (or (member (car entry) '(*export* export import))
			     (and (pair? *export*)
				  (not (member (car entry) *export*))))
			 (values)
			 entry))
		   (curlet))))))

(unless (defined? 'r7rs-import-library-filename)
  (define (r7rs-import-library-filename libs)    ; this turns (A B) into "A/B.scm", then loads it if needed
    (when (pair? libs)
      (unless (eq? (caar libs) 'scheme)
        (let ((lib-filename (let loop ((lib (if (memq (caar libs) '(only except prefix rename))
						(cadar libs)
						(car libs)))
				       (name ""))
			      (set! name (string-append name (symbol->string (car lib))))
			      (if (null? (cdr lib))
				  (string-append name ".scm")
				  (begin
				    (set! name (string-append name "/")) ; this follows Guile, Chibi, and Racket
				    (loop (cdr lib) name))))))
	  (unless (member lib-filename (*s7* 'file-names))
	    (load lib-filename))))
      (r7rs-import-library-filename (cdr libs)))))

(define-macro (import . libs)
  `(begin
     (r7rs-import-library-filename ',libs)
     (varlet (curlet)
       ,@(map (lambda (lib)
		(case (car lib)
		  ((only)
		   `((lambda (e names)
		       (apply inlet
			      (map (lambda (name)
				     (cons name (e name)))
				   names)))
		     (symbol->value (symbol (object->string (cadr ',lib))))
		     (cddr ',lib)))

		  ((except)
		   `((lambda (e names)
		       (apply inlet
			      (map (lambda (entry)
				     (if (member (car entry) names)
					 (values)
					 entry))
				   e)))
		     (symbol->value (symbol (object->string (cadr ',lib))))
		     (cddr ',lib)))

		  ((prefix)
		   `((lambda (e prefx)
		       (apply inlet
			      (map (lambda (entry)
				     (cons (string->symbol
					    (string-append (symbol->string prefx)
							   (symbol->string (car entry))))
					   (cdr entry)))
				   e)))
		     (symbol->value (symbol (object->string (cadr ',lib))))
		     (caddr ',lib)))

		  ((rename)
		   `((lambda (e names)
		       (apply inlet
			      (map (lambda (entry)
				     (let ((info (assoc (car entry) names)))
				       (if info
					   (cons (cadr info) (cdr entry))
					   entry))) ; I assume the un-renamed ones are included
				   e)))
		     (symbol->value (symbol (object->string (cadr ',lib))))
		     (cddr ',lib)))

		  (else
		   `(let ((sym (symbol (object->string ',lib))))
		      (if (not (defined? sym))
			  (format () "~A not loaded~%" sym)
			  (symbol->value sym))))))
	      libs))))


;; delay and force: ugh
(define (make-promise obj)
  (if (promise? obj)
      obj
      (list (cons #t (lambda () obj)) '+promise+)))

(define (promise? obj) 
  (and (pair? obj)
       (pair? (cdr obj))
       (eq? (cadr obj) '+promise+)))

(define-macro (delay expr)
  `(list (cons #f (lambda () ,expr)) '+promise+))

(define-macro (delay-force expr)
  `(make-promise ,expr))

(define (force promise)
  (if (caar promise)
      (if (procedure? (cdar promise))
	  ((cdar promise))
	  (cdar promise))
      (let ((promise* ((cdar promise))))
        (set-car! (car promise) #t)
	(set-cdr! (car promise) promise*)
	promise*)))


;; floor/ and truncate/ can't work as intended: they assume that multiple values
;;   are not spliced.  The "division library" is a trivial, pointless micro-optimization.
;; and why no euclidean-rationalize or exact-integer-expt?
;;   (imagine what will happen when r8rs stumbles on the zoo of continued fraction algorithms!)

(define (jiffies-per-second) 1000000000)
(define (current-jiffy)
  (with-let *libc*
    (let ((res (clock_gettime CLOCK_REALTIME)))
      (+ (* 1000000000 (cadr res)) (caddr res)))))
(define (current-second) (* 1.0 ((*libc* 'time) (c-pointer 0 'time_t*))))

(define get-environment-variable getenv)
(define get-environment-variables (*libc* 'getenvs))

(define (os-type) (car ((*libc* 'uname))))
(define (cpu-architecture) (cadr ((*libc* 'uname))))
(define (machine-name) (caddr ((*libc* 'uname))))
(define (os-version) (string-append (list-ref ((*libc* 'uname)) 3) " " (list-ref ((*libc* 'uname)) 4))) ; or perhaps use /etc/os-release
(define (implementation-name) (copy "s7"))
(define (implementation-version) (substring (*s7* 'version) 3 7))

(unless (defined? 'null-environment)
  (define (null-environment . args) (rootlet)))
(define (environment . args) (rootlet))

;; command-line is problematic: s7 has no access to the caller's "main" function, and
;;   outside Windows, there's no reasonable way to get these arguments.
;;   in Linux, you might win with:

(define (command-line)
  (let ((lst ()))
    (with-input-from-file "/proc/self/cmdline"
      (lambda ()
	(do ((c (read-char) (read-char))
	     (s ""))
	    ((eof-object? c)
	     (reverse lst))
	  (if (char=? c #\null)
	      (begin
		(set! lst (cons s lst))
		(set! s ""))
	      (set! s (string-append s (string c)))))))))


;; records
(define-macro (define-record-type type make ? . fields)
  (let ((obj (gensym))
	(typ (gensym)) ; this means each call on this macro makes a new type
	(args (map (lambda (field)
		     (values (list 'quote (car field))
			     (let ((par (memq (car field) (cdr make))))
			       (and (pair? par) (car par)))))
		   fields)))
    `(begin
       (define (,? ,obj)
	 (and (let? ,obj)
	      (eq? (let-ref ,obj ',typ) ',type)))

       (define ,make
         (inlet ',typ ',type ,@args))

       ,@(map
	  (lambda (field)
	    (when (pair? field)
	      (if (null? (cdr field))
		  (values)
		  (if (null? (cddr field))
		      `(define (,(cadr field) ,obj)
			 (let-ref ,obj ',(car field)))
		      `(begin
			 (define (,(cadr field) ,obj)
			   (let-ref ,obj ',(car field)))
			 (define (,(caddr field) ,obj val)
			   (let-set! ,obj ',(car field) val)))))))
	  fields)
       ',type)))

;;; srfi 111:
(define-record-type box-type (box value) box? (value unbox set-box!))

;;; as per the comment above,
;;; <1> (load "r7rs.scm")
;;;   box-type
;;; <2> (define b1 (box 32))
;;;   (inlet '{gensym}-1 box-type 'value 32)
;;; <3> (define-record-type box-type (box value) box? (value unbox set-box!))
;;;   box-type
;;; <4> (define b2 (box 32))
;;;   (inlet '{gensym}-3 box-type 'value 32)
;;; <5> (box? b1)
;;;   #f
;;; <6> (box? b2)
;;;   #t
;;; but, of course:
;;; <7> (define b3 (box 32))
;;;  (inlet '{gensym}-3 box-type 'value 32)
;;; <8> (equal? b2 b3)
;;;  #t
;;; <9> (box? b3)
;;;  #t


#|
;(require stuff.scm)

;;; more than r7rs desires I think:
(define-macro (define-record-type type make ? . fields)
  (let ((new-type (if (pair? type) (car type) type))
	(inherited (if (pair? type) (cdr type) ()))
	(obj (gensym))
	(new-obj (gensym)))
    `(begin
       (define-class ,new-type ,inherited   ; from stuff.scm
         (map (lambda (f) (if (pair? f) (car f) f)) ',fields))

       (define ,?    ; perhaps the define-class type predicate should use this
	 (let ()
	   (define (search-inherited ,obj type)
	     (define (search-inheritors objs type)
	       (and (pair? objs)
		    (or (search-inherited (car objs) type)
			(search-inheritors (cdr objs) type))))
	     (or (eq? (let-ref ,obj 'class-name) type)
		 (search-inheritors (let-ref ,obj 'inherited) type)))
	   (lambda (,obj)
	     (and (let? ,obj)
		  (search-inherited ,obj ',new-type)))))

       (define ,make
         (let ((,new-obj (copy ,new-type)))
	   ,@(map (lambda (slot)
		    `(let-set! ,new-obj ',slot ,slot))
		  (cdr make))
	   ,new-obj))

       ,@(map
	  (lambda (field)
	    (when (pair? field)
	      (if (null? (cdr field))
		  (values)
		  (if (null? (cddr field))
		      `(define (,(cadr field) ,obj)
			 (let-ref ,obj ',(car field)))
		      `(begin
			 (define (,(cadr field) ,obj)
			   (let-ref ,obj ',(car field)))
			 (define (,(caddr field) ,obj val)
			   (let-set! ,obj ',(car field) val)))))))
	  fields)
       ',new-type)))

;;; vector form is slower:
(define-macro (define-record-type type make ? . fields)
  (let* ((obj (gensym))
	 (args (map (lambda (field)
		      (let ((par (memq (car field) (cdr make))))
			(if (pair? par) (car par) #f)))
		    fields)))
    `(begin
       (define (,? obj)
	 (and (vector? obj)
	      (eq? (vector-ref obj 0) ',type)))

       (define ,make
	 (vector ',type ,@args))

       ,@(map
	  (let ((pos 0))
	    (lambda (field)
	      (set! pos (+ pos 1))
	      (when (pair? field)
		(if (null? (cdr field))
		    (values)
		    (if (null? (cddr field))
			`(define (,(cadr field) ,obj)
			   (vector-ref ,obj ,pos))
			`(begin
			   (define (,(cadr field) ,obj)
			     (vector-ref ,obj ,pos))
			   (define (,(caddr field) ,obj val)
			     (vector-set! ,obj ,pos val))))))))
	  fields)
       ',type)))
|#
