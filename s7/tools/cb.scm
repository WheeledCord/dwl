(set! (*s7* 'heap-size) 1024000)

(define factor 1)

(define (map-iota proc limit)
  (let loop ((i 0) (result ()))
    (if (< i limit)
        (loop (+ i 1) (cons (proc i) result))
        (reverse result))))

(define (pascal n k)
  (cond ((or (= k 0) (= k n))
         1)
        ((< 0 k n)
         (+ (pascal (- n 1) (- k 1))
            (pascal (- n 1) k)))
        (else
         (error 'bad-indices n k))))

(define (pascal-row n)
  (map-iota (lambda (k) (pascal n k))
            (+ n 1)))

(define (pascal-test)
  (do ((i 0 (+ i 1)))
      ((= i (* factor 15)))
    (map-iota pascal-row (+ 1 (modulo i 20)))))
;; => ((1)
;;     (1 1)
;;     (1 2 1)
;;     (1 3 3 1)
;;     (1 4 6 4 1)
;;     (1 5 10 10 5 1)
;;     (1 6 15 20 15 6 1)
;;     (1 7 21 35 35 21 7 1)
;;     (1 8 28 56 70 56 28 8 1)
;;     (1 9 36 84 126 126 84 36 9 1))

(pascal-test)

;;;; --------------------------------------------------------------------------------

;; this is not the original version

(define (integer->list num) 
  (let ((sign (negative? num))) 
    (let loop ((n (abs num)) (digits ()))
      (if (< n 10) 
          (if sign 
              (cons '- (cons n digits))
              (cons n digits))
	  (loop (quotient n 10) (cons (remainder n 10) digits))))))

(integer->list 123450)
;; ==> (1 2 3 4 5 0)

(integer->list -123450)
;; ==> (- 1 2 3 4 5 0)

(integer->list 0)
;; ==> (0)

(define (int->list-test)
  (do ((i 0 (+ i 1)))
      ((= i (* factor 150000)))
    (integer->list i)))

(int->list-test)

;;;; --------------------------------------------------------------------------------

(define combine3
  (letrec ((tails-of
	    (lambda (set)
              (cond ((null? set)
                     ())
		    (else
                     (cons set (tails-of (cdr set)))))))
	   (combinations
	    (lambda (n set rest)
	      (case n
		((0 0.0) ())
		((1) (map list set))
		(else
		 (apply append
			(map (lambda (tail)
			       (map (lambda (sub) (cons (car tail) sub)) (combinations (- n 1) (rest tail) rest)))
			     (tails-of set))))))))
    (lambda (n set rest)
      (combinations n set rest))))

;; create k-combination without repetion
(define (combine n set)
  (combine3 n set cdr))

;; create k-combination with repetition
(define (combine* n set)
  (combine3 n set (lambda (x) x)))

(combine 2 '(a b c))
;; ==> ((a b) (a c) (b c))

(combine* 2 '(a b c))
;; ==>  ((a a) (a b) (a c) (b b) (b c) (c c))

(define (combine-test)
  (do ((i 0 (+ i 1)))
      ((= i (* factor 30000)))
    (combine 2 '(a b c))
    (combine* 2 '(a b c))))

(combine-test)

;;;; --------------------------------------------------------------------------------

(define (most-frequent xs counters)
  (if (null? xs)
      (let find-max-count ((counters counters)
                           (best #f))
        (if (null? counters)
            (and best (car best))
            (find-max-count (cdr counters)
                            (let* ((counter (car counters))
                                   (count (cdr counter)))
                              (if (and (> count 1)
                                       (or (not best) (> count (cdr best))))
                                  counter
                                  best)))))
      (most-frequent (cdr xs)
                     (let* ((x (car xs))
                            (counter (assoc x counters)))
                       (if (not counter)
                           (cons (cons x 1) counters)
                           (begin
                             (set-cdr! counter (+ (cdr counter) 1))
                             counters))))))

(unless (= (most-frequent '(1 2 3 4 2 3 4 2 2 2) ()) 2) (format *stderr* "most-frequent not 2\n"))
;; ==> 2

(when (most-frequent '(1 2 3 4 5 6 7) ()) (format *stderr* "most-frequent?\n"))
;; ==> #f

(define (freq-test)
  (do ((i 0 (+ i 1)))
      ((= i (* factor 50000)))
    (most-frequent '(1 2 3 4 2 3 4 2 2 2) ())
    (most-frequent '(1 2 3 4 5 6 7) ())))

(freq-test)

;;;; --------------------------------------------------------------------------------

(define (string-split char-delimiter? string)
  (define (maybe-add a b parts)
    (if (= a b) parts (cons (substring string a b) parts)))
  (let ((n (string-length string)))
    (let loop ((a 0) (b 0) (parts ()))
      (if (< b n)
          (if (not (char-delimiter? (string-ref string b)))
              (loop a (+ b 1) parts)
              (loop (+ b 1) (+ b 1) (maybe-add a b parts)))
          (reverse (maybe-add a b parts))))))

(string-split char-whitespace? "")
;; ==> ()

(string-split char-whitespace? " \t  ")
;; ==> ()

(string-split char-whitespace? "ab")
;; ==> ("ab")

(string-split char-whitespace? "ab   c  d \t efg ")
;; ==> ("ab" "c" "d" "efg")

(define (split-test)
  (do ((i 0 (+ i 1)))
      ((= i (* factor 50000)))
    (string-split char-whitespace? " \t  ")
    (string-split char-whitespace? "ab   c  d \t efg ")))

(split-test)

;;;; --------------------------------------------------------------------------------

(define (filter p lst)
  (cond ((not (pair? lst)) lst)
	((not (p (car lst))) (filter p (cdr lst)))
	(else (cons (car lst)
		    (filter p (cdr lst))))))

(define (topological-sort nodes eq)
  (let ((table (map (lambda (n) (cons (car n) 0)) nodes))
	(queue ())
	(result ()))
    
    (define (set-up)
      ;; Compute the number of nodes that each node depends on.
      (for-each
       (lambda (node)
	 (for-each
          (lambda (to)
            (let ((p (assoc to table eq)))
              (if p
                  (set-cdr! p (+ 1 (cdr p)))
                  (set! table (cons (cons to 1) table)))))
          (cdr node)))
       nodes))
    
    (define (traverse)
      (unless (null? queue)
	(let ((nq (car queue)))
          (set! queue (cdr queue))
          (let ((n0 (assoc nq nodes eq)))
            (when n0
              (for-each
               (lambda (to)
		 (let ((p (assoc to table eq)))
                   (when p
                     (let ((cnt (- (cdr p) 1)))
                       (when (zero? cnt)
			 (set! result (cons to result))
			 (set! queue (cons to queue)))
                       (set-cdr! p cnt)))))
               (cdr n0)))
            (traverse)))))

    (set-up)
    (set! queue (map car (filter (lambda (p) (zero? (cdr p))) table)))
    (set! result queue)
    (traverse)
    (let ((rest (filter (lambda (e) (not (zero? (cdr e)))) table)))
      (unless (null? rest)
	(error 'bad-data (list "Graph has circular dependency: ~S" (map car rest)))))
    (reverse result)))

(topological-sort '((shirt tie belt)
                    (tie jacket)
                    (belt jacket)
                    (watch)
                    (pants shoes belt)
                    (undershorts pants shoes)
                    (socks shoes))
                  eqv?)
;; => (socks undershorts watch shirt tie pants belt jacket shoes)

(catch #t
  (lambda ()
    (topological-sort '((shirt watch)
			(watch tie)
			(tie watch))
                      eqv?))
  (lambda (typ info)
    #f))
;; Raises an exception.

(define (topo-test)
  (do ((i 0 (+ i 1)))
      ((= i (* factor 20000)))
    (topological-sort '((shirt tie belt)
			(tie jacket)
			(belt jacket)
			(watch)
			(pants shoes belt)
			(undershorts pants shoes)
			(socks shoes))
                      eqv?)))

(topo-test)

;;;; --------------------------------------------------------------------------------

(define iota
  (let ((+documentation+ "(iota n (start 0) (incr 1)) returns a list counting from start for n:\n\
    (iota 3) -> '(0 1 2)"))
    (lambda* (n (start 0) (incr 1))
      (if (or (not (integer? n))
	      (< n 0))
	  (error 'wrong-type-arg "iota length ~A should be a non-negative integer" n))
      (let ((lst (make-list n)))
	(do ((p lst (cdr p))
	     (i start (+ i incr)))
	    ((null? p) lst)
	  (set! (car p) i))))))

(define (group-by f lst)
  (if (null? lst) ()
      (let ((first (car lst)))
        (let loop ((lst (cdr lst))
                   (key (f first))
                   (group (list first))
                   (groups ()))
          (if (null? lst)
              (reverse (cons (reverse group) groups))
              (let ((newkey (f (car lst))))
                (if (equal? key newkey)
                    (loop (cdr lst) key
                          (cons (car lst) group)
                          groups)
                    (loop (cdr lst) newkey
                          (list (car lst))
                          (cons (reverse group) groups)))))))))

(group-by even? (iota 10))
;; ==> ((0) (1) (2) (3) (4) (5) (6) (7) (8) (9))

(group-by odd? '(1 3 5 2 1 6 4 1 7))
;; ==> ((1 3 5) (2) (1) (6 4) (1 7))

(group-by string-length '("aa" "bb" "ccc" "dddd" "eeee" "ffff" "g" "h"))
;; ==> (("aa" "bb") ("ccc") ("dddd" "eeee" "ffff") ("g" "h"))

(group-by (lambda (i) (quotient i 3)) (iota 20))
;; ==> ((0 1 2) (3 4 5) (6 7 8) (9 10 11) (12 13 14) (15 16 17) (18 19))

(define (group-test)
  (do ((i 0 (+ i 1)))
      ((= i (* factor 20000)))
    (group-by odd? '(1 3 5 2 1 6 4 1 7))
    (group-by string-length '("aa" "bb" "ccc" "dddd" "eeee" "ffff" "g" "h"))
    (group-by (lambda (i) (quotient i 3)) (iota 20))))

(group-test)

;;;; --------------------------------------------------------------------------------

(define (string-join1 lst delimiter)
  (if (null? lst) ""
      (let loop ((result (car lst)) (lst (cdr lst)))
        (if (null? lst)
            result
            (loop (string-append result delimiter (car lst))
                  (cdr lst))))))

(define (string-join2 lst delimiter)
  (if (null? lst) ""
      (call-with-output-string
       (lambda (out)
         (write-string (car lst) out)
         (for-each (lambda (item)
                     (write-string delimiter out)
                     (write-string item out))
                   (cdr lst))
         (get-output-string out)))))

(string-join1 '("foo" "bar" "baz") ":")
;; ==> "foo:bar:baz"

(string-join2 '("foo" "bar" "baz") ":")

(define (join-test)
  (do ((i 0 (+ i 1)))
      ((= i (* factor 200000)))
    (string-join1 '("foo" "bar" "baz") ":")
    (string-join2 '("foo" "bar" "baz") ":")))

(join-test)

;;; ================================================================================

(define dft ; K Dybvig I think (I forgot to write down the source)
  (let ()
    (define (w-powers n)
      (let ((delta (/ (* 0-2.0i pi) n)))
	(let f ((n n) (x 0.0))
          (if (= n 0)
              ()
              (cons (exp x) (f (- n 2) (+ x delta)))))))
    (define (evens w)
      (if (null? w)
          ()
          (cons (car w) (evens (cddr w)))))
    (define (interlace x y)
      (if (null? x)
          ()
          (cons (car x) (cons (car y) (interlace (cdr x) (cdr y))))))
    (define (split ls)
      (let split ((fast ls) (slow ls))
	(if (null? fast)
            (values () slow)
            ((lambda (front back)
               (values (cons (car slow) front) back))
             (split (cddr fast) (cdr slow))))))
    (define (butterfly x w)
      ((lambda (front back)
	 (values
          (map + front back)
          (map * (map - front back) w)))
       (split x)))
    (define (rfft x w)
      (if (null? (cddr x))
	  (let ((x0 (car x)) (x1 (cadr x)))
            (list (+ x0 x1) (- x0 x1)))
	  ((lambda (front back)
             (let ((w (evens w)))
               (interlace (rfft front w) (rfft back w))))
	   (butterfly x w))))
    (lambda (x)
      (rfft x (w-powers (length x))))))

(display (dft (make-list 8 1.0))) (newline)
(define (f)
  (let ((L (make-list 1024 0.0)))
    (do ((i 0 (+ i 1)))
	((= i 200))
      (set! (L i) 1.0)
      (dft L))))
(f)

;;; --------------------------------------------------------------------------------
;;; char-type tests for the eof-object first, since the eof-object
;;; may not be a valid argument to char-alphabetic? or char-numeric?
;;; It returns the eof-object, the symbol letter, the symbol digit,
;;; or the argument itself if it is not a letter or digit.
(define char-type
  (lambda (c)
    (cond
     ((eof-object? c) c)
     ((char-alphabetic? c) 'letter)
     ((char-numeric? c) 'digit)
     (else c))))

;;; If the next character on p is a letter, get-word reads a word
;;; from p and returns it in a string.  If the character is not a
;;; letter, get-word returns the character (on eof, the eof-object).
(define get-word
  (lambda (p)
    (let ((c (read-char p)))
      (if (eq? (char-type c) 'letter)
          (list->string
           (let loop ((c c))
             (cons c
                   (if (memq (char-type (peek-char p)) '(letter digit))
                       (loop (read-char p))
                       ()))))
          c))))

;;; Trees are represented as vectors with four fields: word, left,
;;; right, and counter.  Only one field, word, is initialized by an
;;; argument to the constructor procedure make-tree.  The remaining
;;; fields are explicitly initialized and changed by subsequent
;;; operations.  Most Scheme systems provide structure definition
;;; facilities that automate creation of structure manipulation
;;; procedures, but we simply define the procedures by hand here.
(define-expansion (make-tree word) `(vector ,word () () 1))
(define-expansion (tree-word tree) `(vector-ref ,tree 0))
(define-expansion (tree-left tree) `(vector-ref ,tree 1))
(define-expansion (set-tree-left! tree new-left) `(vector-set! ,tree 1 ,new-left))
(define-expansion (tree-right tree) `(vector-ref ,tree 2))
(define-expansion (set-tree-right! tree new-right) `(vector-set! ,tree 2 ,new-right))
(define-expansion (tree-counter tree) `(vector-ref ,tree 3))
(define-expansion (set-tree-counter! tree new-counter) `(vector-set! ,tree 3 ,new-counter))

;;; If the word already exists in the tree, tree increments its
;;; counter.  Otherwise, a new tree node is created and put into the
;;; tree.  In any case, the new or modified tree is returned.
(define tree
  (lambda (node word)
    (cond
     ((null? node) (make-tree word))
     ((string=? word (tree-word node))
      (set-tree-counter! node (+ (tree-counter node) 1))
      node)
     ((string<? word (tree-word node))
      (set-tree-left! node (tree (tree-left node) word))
      node)
     (else
      (set-tree-right! node (tree (tree-right node) word))
      node))))

;;; tree-print prints the tree in "in-order," i.e., left subtree,
;;; then node, then right subtree.  For each word, the counter and the
;;; word are printed on a single line.
(define tree-print
  (lambda (node p)
    (unless (null? node)
      (tree-print (tree-left node) p)
      (format p "~S ~A~%" (tree-counter node) (tree-word node))
      (tree-print (tree-right node) p))))

;;; frequency is the driver routine.  It opens the files, reads the
;;; words, and enters them into the tree.  When the input port
;;; reaches end-of-file, it prints the tree and closes the ports.
(define frequency
  (lambda (infn outfn)
    (let ((ip (open-input-file infn))
          (op (open-output-file outfn)))
      (let loop ((root ()))
        (let ((w (get-word ip)))
          (cond
           ((eof-object? w) (tree-print root op))
           ((string? w) (loop (tree root w)))
           (else (loop root)))))
      (close-input-port ip)
      (close-output-port op))))

(frequency "lint.scm" "dybtest")

;;; --------------------------------------------------------------------------------
;;; code from Rosetta scheme examples slightly edited to provide timing tests

;(load "r7rs.scm")
(define (square x) (* x x))

;;; barnsley fern

(define create-fern 
  (let ()
    (define (new-point xn yn)
      (let ((r (random 100.0))) ;(* 100 (random-real))))
	(cond ((< r 1) ; f1
               (list 0 (* 0.16 yn)))
              ((< r 86) ; f2
               (list (+ (* 0.85 xn) (* 0.04 yn))
                     (+ (* -0.04 xn) (* 0.85 yn) 1.6)))
              ((< r 93) ; f3
               (list (- (* 0.2 xn) (* 0.26 yn))
                     (+ (* 0.23 xn) (* 0.22 yn) 1.6)))
              (else ; f4
               (list (+ (* -0.15 xn) (* 0.28 yn))
                     (+ (* 0.26 xn) (* 0.24 yn) 0.44))))))
    (lambda (x y num-points)
      (do ((i 0 (+ i 1))
	   (pts (list (list x y)) (cons (new-point (caar pts) (cadar pts)) pts)))
	  ((= i num-points) pts)))))
    
;; output the fern to an eps file
(define (output-fern-as-eps filename fern)
  (when (file-exists? filename) (delete-file filename))
  (with-output-to-file
      filename
    (lambda ()
      (let* ((width 600)
             (height 800)
             (min-x (apply min (map car fern)))
             (max-x (apply max (map car fern)))
             (min-y (apply min (map cadr fern)))
             (max-y (apply max (map cadr fern)))
             (scale-x (/ (- width 50) (- max-x min-x)))
             (scale-y (/ (- height 50) (- max-y min-y)))
             (scale-points (lambda (point)
                             (list (truncate (+ 20 (* scale-x (- (car point) min-x))))
                                   (truncate (+ 20 (* scale-y (- (cadr point) min-y))))))))
	
        (format () "%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 ~D ~D~%" width height)
        ;; add each point in fern as an arc - sets linewidth based on depth in tree
        (for-each (lambda (point)
                    (format () "~D ~D 0.1 0 360 arc\nstroke\n" (car point) (cadr point)))
                  (map scale-points fern))
        (display "\n%%EOF")))))

(do ((i 0 (+ i 1)))
    ((= i 4))
  (output-fern-as-eps "barnsley.eps" (create-fern 0 0 50000)))

;;; --------------------------------------------------------------------------------

;;; circles through 2 points

;; c1 and c2 are pairs (x y), r a positive radius
(define find-circles
  (let ((x-coord car) ; for easier to read coordinate extraction from list
	(y-coord cadr))
    (define (approx= a b) (< (- a b) 0.000001)) ; equal within tolerance
    (define (avg a b) (/ (+ a b) 2))
    (define (distance pt1 pt2)
      (sqrt (+ (square (- (x-coord pt1) (x-coord pt2)))
               (square (- (y-coord pt1) (y-coord pt2))))))
    (define (equal-points? pt1 pt2)
      (and (approx= (x-coord pt1) (x-coord pt2))
           (approx= (y-coord pt1) (y-coord pt2))))
    (define (delete-duplicate pts) ; assume no more than two points in list
      (if (and (= 2 (length pts))
               (equal-points? (car pts) (cadr pts)))
	  (list (car pts)) ; keep the first only
	  pts))
    
    (lambda (c1 c2 r)					;
      (let ((d (distance c1 c2)))
	(cond ((equal-points? c1 c2) ; coincident points
               (if (> r 0)
		   'infinite   ; r > 0
		   (list c1))) ; else r = 0
              ((or (< (* 2 r) d)    ; circle cannot reach both points, as too far apart
		   (approx= r 0.0)) ; r = 0, no circles, as points differ
               ())
              (else ; find up to two circles meeting c1 and c2
               (let* ((mid-pt (list (avg (x-coord c1) (x-coord c2))
                                    (avg (y-coord c1) (y-coord c2))))
                      (offset (sqrt (- (square r) 
                                       (square (* 0.5 d)))))
                      (delta-cx (/ (- (x-coord c1) (x-coord c2)) d))
                      (delta-cy (/ (- (y-coord c1) (y-coord c2)) d)))
		 (delete-duplicate
		  (list (list (- (x-coord mid-pt) (* offset delta-cx))
                              (+ (y-coord mid-pt) (* offset delta-cy)))
			(list (+ (x-coord mid-pt) (* offset delta-cx))
                              (- (y-coord mid-pt) (* offset delta-cy))))))))))))

(define (test-circles)
  (let ((c1 '((0.1234 0.9876) (0.0000 2.0000) (0.1234 0.9876) (0.1234 0.9876) (0.1234 0.9876)))
	(c2 '((0.8765 0.2345) (0.0000 0.0000) (0.1234 0.9876) (0.8765 0.2345) (0.1234 0.9876)))
	(r '(2.0 1.0 2.0 0.5 0.0)))
    (do ((i 0 (+ i 1)))
	((= i 10000))
      (for-each find-circles c1 c2 r))))

(test-circles)

;;; --------------------------------------------------------------------------------

;;; compare strings
(define-constant (compare-strings fn strs)
  (or (null? strs)                             ; returns #t on empty list
      (null? (cdr strs))                       ; returns #t on list of size 1
      (do ((fst strs (cdr fst))
           (snd (cdr strs) (cdr snd)))
          ((or (null? snd)
               (not (fn (car fst) (car snd))))
           (null? snd)))))                       ; returns #t if the snd list is empty, meaning all comparisons are exhausted

(define (test-compare)
  (let ((strings (list "AA AA AA AA" "AA ACB BB CC"))) 
    (do ((i 0 (+ i 1)))
	((= i 100000))
      (compare-strings string=? strings) ; test for all equal
      (compare-strings string<? strings)))) ; test for in ascending order

(test-compare)

;;; --------------------------------------------------------------------------------

;;; ordered words unixdict.txt

(define (test-words)
  (do ((i 0 (+ i 1)))
      ((= i 4))
    (let ((port (open-input-file "~/cl/unixdict.txt")))
      (let loop ((char (read-char port)) (word ()) (result '(())))
	(case char
	  ((#<eof>)
	   (reverse (map (lambda (word) (apply string word)) result)))
	  ((#\newline)
	   (loop (read-char port) ()
		 (let ((best-length (length (car result))) (word-length (length word)))
		   (cond
		    ((or (< word-length best-length) (not (apply char>=? word))) result)
		    ((> word-length best-length) (list (reverse word)))
		    (else (cons (reverse word) result))))))
	  (else (loop (read-char port) (cons char word) result)))))))

(test-words)

;;; --------------------------------------------------------------------------------

;;; same fringe

; binary tree helpers from "Structure and Interpretation of Computer Programs" 2.3.3
(define entry car)
(define left-branch cadr)
(define right-branch caddr)
;;; -- unused: (define (make-tree entry left right) (list entry left right))

; returns a list of leftmost nodes from each level of the tree
(define (descend tree ls)
  (if (null? (left-branch tree))
      (cons tree ls)
      (descend (left-branch tree) (cons tree ls))))

; updates the list to contain leftmost nodes from each remaining level
(define (ascend ls)
  (if (null? (right-branch (car ls))) 
      (if (null? (cdr ls)) () (cdr ls))
      (let ((ls (cons (right-branch (car ls)) (cdr ls))))
        (if (null? (left-branch (car ls)))
            ls
            (descend (left-branch (car ls)) ls)))))

; loops thru each list until the end (true) or nodes are unequal (false)
(define (same-fringe? t1 t2)
  (let next ((l1 (descend t1 ()))
	     (l2 (descend t2 ())))
    (cond
     ((and (null? l1) (null? l2)) #t)
     ((or (null? l1)
	  (null? l2)
	  (not (eq? (entry (car l1)) (entry (car l2))))) #f)
     (else (next (ascend l1) (ascend l2))))))

;;;Output:
;;; > (same-fringe? (list 1 () (list 2 () (list 3 () ()))) (list 3 (list 2 (list 1 () ()) ()) ()))
;;; #t

(define (fringe)
  (do ((i 0 (+ i 1)))
      ((= i 30000))
    (same-fringe? (list 1 () (list 2 () (list 3 () ()))) (list 3 (list 2 (list 1 () ()) ()) ()))))

(fringe)

;;; --------------------------------------------------------------------------------

;;; vector products

(define (dot-product A B)
  (apply + (map * A B)))
#|
  ;; slower! (int_optimize)
  (let ((len (min (length A) (length B)))
	(sum 0))
    (do ((i 0 (+ i 1)))
	((= i len) sum)
      (set! sum (+ sum (* (int-vector-ref A i) (int-vector-ref B i)))))))
|#

(define (cross-product A B)
  (let* ((len (vector-length A))
	 (xp (make-int-vector len)))
    (let loop ((n 0))
      (int-vector-set! xp n (- (* (int-vector-ref A (modulo (+ n 1) len))
				  (int-vector-ref B (modulo (+ n 2) len)))
			       (* (int-vector-ref A (modulo (+ n 2) len))
				  (int-vector-ref B (modulo (+ n 1) len)))))
      (if (= len (+ n 1))
	  xp
	  (loop (+ n 1))))))

(define (scalar-triple-product A B C)
  (dot-product A (cross-product B C)))

(define (vector-triple-product A B C)
  (cross-product A (cross-product B C)))


(define A #i(3 4 5))
(define B #i(4 3 5))
(define C #i(-5 -12 -13))

(define (test-product)
  (do ((i 0 (+ i 1)))
      ((= i 10000))
    (dot-product A B)
    (cross-product A B)
    (scalar-triple-product A B C)
    (vector-triple-product A B C)))

(test-product)

;;; --------------------------------------------------------------------------------

;;; gnome sort

(define (gnome-sort-compar in-order input-list)
  (let gnome ((p (list (car input-list)))
              (n (cdr input-list)))
    (if (null? n) ; no more flowerpots?
        p ; we're done
        (let ((prev-pot (car p))
              (next-pot (car n)))
          (if (in-order next-pot prev-pot)
					; if the pots are in order, step forwards.
					; otherwise, exchange the two pots, and step backwards.
              (gnome (cons next-pot p) ; Prev list grows
                     (cdr n)) ; Next list shorter by one
              (if (null? (cdr p)) ; are we at the beginning?
                  (gnome                    ; if so, we can't step back
                   (list next-pot)          ; simply exchange the pots without
                   (cons prev-pot (cdr n))) ; changing lengths of lists
                  (gnome
                   (cdr p) ; Prev list shorter by one
                   (cons next-pot (cons prev-pot (cdr n))))))))))

;;; (gnome-sort-compar <= '(98 36 2 78 5 81 32 90 73 21 94 28 53 25 10 99))
;;; (2 5 10 21 25 28 32 36 53 73 78 81 90 94 98 99)

;;; (display (gnome-sort-compar <= '(98 36 2 78 5 81 32 90 73 21 94 28 53 25 10 99))) (newline)

(define (test-gnome)
  (do ((i 0 (+ i 1)))
      ((= i 5000))
    (gnome-sort-compar <= '(98 36 2 78 5 81 32 90 73 21 94 28 53 25 10 99))))

(test-gnome)

;;; --------------------------------------------------------------------------------

;;; heapsort

(define (swap! v i j)                   ; swap two elements of a vector
  (let ((temp (vector-ref v i)))
    (vector-set! v i (vector-ref v j))
    (vector-set! v j temp)))

(define (sift-down! v start end)        ; sift element at node start into place
  (let ((child (+ (* start 2) 1)))
    (cond
     ((> child end) 'done) ; start has no children
     (else
					; if child has a sibling node whose value is greater ...
      (if (and (<= (+ child 1) end)
               (< (vector-ref v child) (vector-ref v (+ child 1))))
					; ... then we'll look at the sibling instead
           (set! child (+ child 1)))
      (if (< (vector-ref v start) (vector-ref v child))
          (begin
            (swap! v start child)
            (sift-down! v child end))
          'done)))))

(define heapify                         ; transform v into a binary max-heap
  (let ()
    (define (iter v len) 
      (do ((start (quotient (- len 2) 2) (- start 1)))
          ((< start 0) 'done)
        (sift-down! v start (- len 1))))
    (lambda (v)
      (iter v (vector-length v)))))

(define heapsort
  (let ()
    (define (iter v end) 
      (do ((v v)
           (end end (- end 1)))
          ((zero? end) 'done) ; why not return v??
        (swap! v 0 end)
        (sift-down! v 0 (- end 1))))
    (lambda (v)
      (heapify v)
      (iter v (- (vector-length v) 1)))))

(let ((v (vector 3 5 7 9 0 8 1 4 2 6)))
  (heapsort v)
  (unless (equal? v (vector 0 1 2 3 4 5 6 7 8 9))
    (format *stderr* "heapsort: ~S~%" v)))

(define (test-heap)
  (do ((i 0 (+ i 1))
       (uriah (vector 3 5 7 9 0 8 1 4 2 6) (vector 3 5 7 9 0 8 1 4 2 6)))
      ((= i 6000))
    (heapsort uriah)))

(test-heap)

;;; --------------------------------------------------------------------------------

;;; sierpinski carpet

(define carpet
  (let ()
    (define (in-carpet? x y)
      (cond ((or (zero? x) (zero? y))
             #t)
            ((= 1 (remainder x 3) (remainder y 3))
             #f)
            (else
             (in-carpet? (quotient x 3) (quotient y 3)))))
    (lambda (n out)
      (do ((i 0 (+ i 1))) ((>= i (expt 3 n)))
	(do ((j 0 (+ j 1))) ((>= j (expt 3 n)))
	  (display (if (in-carpet? i j)
                       #\*
                       #\space)
		   out))
	(newline out)))))

(define (test-carpet)
  (do ((i 0 (+ i 1)))
      ((= i 30))
    (carpet 4 #f)))

(test-carpet)

;;; --------------------------------------------------------------------------------

;;; babbage

(define (digits n)
  (string->list (number->string n)))

(define (starts-with list head)
  (cond ((null? head) #t)
        ((null? list) #f)
        ((equal? (car list) (car head))
	 (starts-with (cdr list) (cdr head)))
	(else #f)))
(define (ends-with list tail)
  (starts-with (reverse list)
               tail))

(define (test-babbage)
  (let ((end (reverse (digits 269696))))
    (do ((i 0 (+ i 1)))
	((= i 5))
      (do ((j 1 (+ j 1)))
	  ((ends-with (digits (* j j)) end) j)))))

(test-babbage)
;; 25264

;;; --------------------------------------------------------------------------------

;;; longest increasing subsequence

(define lis
  (let ()
    (define (bsearch-piles less? x len pile-tops)
      (let aux ((lo 0)
		(hi (- len 1)))
	(if (> lo hi)
	    lo
	    (let ((mid (quotient (+ lo hi) 2)))
	      (if (less? (car (vector-ref pile-tops mid)) x)
		  (aux (+ mid 1) hi)
		  (aux lo (- mid 1)))))))
    (lambda (less? lst)
      (let ((pile-tops (make-vector (length lst))))
	(let aux ((len 0)
		  (lst lst))
	  (if (null? lst)
	      (reverse (vector-ref pile-tops (- len 1)))
	      (let* ((x (car lst))
		     (i (bsearch-piles less? x len pile-tops)))
		(vector-set! pile-tops i (cons x (if (= i 0)
						     ()
						     (vector-ref pile-tops (- i 1)))))
		(aux (if (= i len) (+ len 1) len) (cdr lst)))))))))

(define (test-increase)
  (do ((i 0 (+ i 1)))
      ((= i 5000))
    (lis < '(3 2 6 4 5 1))
    (lis < '(0 8 4 12 2 10 6 14 1 9 5 13 3 11 7 15))))

(test-increase)

(exit)
