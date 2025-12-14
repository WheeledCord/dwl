;;; utf8proc->s7 tests

(load "libutf8proc.scm")

(when (defined? '*libutf8proc*)
  
  (with-let *libutf8proc*

    ;; --------------------------------
    ;; these are from the libutf8proc test directory
    
    (define (print-property c)
      (format *stderr* "  category = ~S~% charwidth = ~D~%~A~%"
	      (utf8proc_category_string c)
	      (utf8proc_charwidth c)
	      (utf8proc_get_property c)))
    
    (do ((c 1 (+ c 1)))
	((= c #x110000))
      (let ((l (utf8proc_tolower c))
	    (u (utf8proc_toupper c)))
	(unless (or (= l c)
		    (utf8proc_codepoint_valid l))
	  (format *stderr* "~X: invalid tolower~%" c))
	(unless (or (= u c)
		    (utf8proc_codepoint_valid u))
	  (format *stderr* "~X: invalid toupper~%" c))
	))
    
    (do ((c 0 (+ c 1)))
	((or (= c #xd800)
	     (and (not (utf8proc_codepoint_valid c))
		  (not (format *stderr* "~X: codepoint invalid~%" c))))))
    
    (do ((c #xd800 (+ c 1)))
	((or (= c #xe000)
	     (and (utf8proc_codepoint_valid c)
		  (not (format *stderr* "~X: codepoint valid?~%" c))))))
    
    (do ((c #xe000 (+ c 1)))
	((or (= c #x110000)
	     (and (not (utf8proc_codepoint_valid c))
		  (not (format *stderr* "~X: codepoint invalid~%" c))))))
    
    (do ((c #x110000 (+ c 1)))
	((or (= c #x110010)
	     (and (utf8proc_codepoint_valid c)
		  (not (format *stderr* "~X: codepoint valid?~%" c))))))
    
    ;; (print-property #xbb)
    
    (do ((c 1 (+ c 1)))
	((= c #x110000))
      (let ((cat ((utf8proc_get_property c) 'category))
	    (w (utf8proc_charwidth c)))
	(if (and (or (= cat UTF8PROC_CATEGORY_MN) (= cat UTF8PROC_CATEGORY_ME))
		 (positive? w))
	    (format *stderr* "nonzero width ~D for combining char ~X~%" w c))
	(if (and (zero? w)
		 (or (and (>= cat UTF8PROC_CATEGORY_LU) (<= cat UTF8PROC_CATEGORY_LO))
		     (and (>= cat UTF8PROC_CATEGORY_ND) (<= cat UTF8PROC_CATEGORY_SC))
		     (and (>= cat UTF8PROC_CATEGORY_SO) (<= cat UTF8PROC_CATEGORY_ZS))))
	    (format *stderr* "zero width for symbol-like char ~X~%" c))))
    ;; --------------------------------

    (define s '("élan ‘quote’")) ; example from Norman Gray
    (display s)       ; ("élan â\x80;\x98;quoteâ\x80;\x99;") -- this is due to write's slashify_table choices: now displays ("élan ‘quote’")
    (newline)
    (display (car s)) ; élan ‘quote’
    (newline)
    
    (define b (string->byte-vector (car s)))
    (format #t "~{~X ~}" b) ;c3 a9 6c 61 6e 20 e2 80 98 71 75 6f 74 65 e2 80 99 
    (newline)
    
    
    (define p (utf8proc_map (car s) UTF8PROC_NULLTERM)) ; is this doing anything useful (besides error checking)?
    (display (car p))       ; élan ‘quote’
    (newline)
    
    (define p1 (utf8proc_map "(\"élan ‘quote’\")" UTF8PROC_NULLTERM))
    (display (car p1))      ; ("élan ‘quote’")
    (newline)
    
    (define b1 (string->byte-vector (car p1)))
    (format #t "~{~X ~}" b1) ;28 22 c3 a9 6c 61 6e 20 e2 80 98 71 75 6f 74 65 e2 80 99 22 29
    (newline)
    
    (define s1 (with-output-to-string (lambda () (display s))))
    (display s1) (newline)  ; ("élan ‘quote’")
    (define p2 (utf8proc_map s1 UTF8PROC_NULLTERM))
    (if (integer? (cdr p2))
	(display (utf8proc_errmsg (cdr p2))) ; "Invalid UTF-8 string" or "unknown error" -- what is the problem here?
	(display (car p2)))
    (newline)
    
    (let ((len (cdr p1))
	  (p1c (copy (car p1))))
      (do ((n (utf8proc_iterate p1c len) (utf8proc_iterate p1c len)))
	  ((<= (car n) 0)) ; (cdr n) is the codepoint as an integer
	(display (substring p1c 0 (car n))) (display #\space) ; ( " é l a n   ‘ q u o t e ’ " )
	(set! p1c (substring p1c (car n)))
	(set! len (- len (car n))))
      (newline))
    
    (let ((e1 (utf8proc_encode_char #x00E9))) ; unicode code-point to utf-8 -> (cons utf-8-string length-thereof)
      (format #t "#x~{~X~}" (string->byte-vector (car e1))) ; #xc3a9
      (newline)
      (display (car e1))      ; é
      (newline))

    (let ((e1 (utf8proc_encode_char #x018b)))
      (format #t "#x~{~X~}" (string->byte-vector (car e1)))
      (newline)
      (display (car e1))      ; latin cap D with top bar
      (newline))

    (let ((e1 (utf8proc_encode_char #x0238)))
      (format #t "#x~{~X~}" (string->byte-vector (car e1)))
      (newline)
      (display (car e1))      ; latin small db digraph
      (newline))

    (let ((e1 (utf8proc_encode_char #x1e00)))
      (format #t "#x~{~X~}" (string->byte-vector (car e1)))
      (newline)
      (display (car e1))      ; latin cap A ring below
      (newline))

    (display (string->symbol "élan ‘quote’"))
    (newline)
    (display (symbol->string (symbol "élan ‘quote’")))
    (newline)
    
  ))
