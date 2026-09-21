;;; nxml-e20.el --- what nxml-mode needs from Emacs 21 on Emacs 20  -*- coding: iso-2022-7bit -*-

;; nxml-mode was written for Emacs 21.  Emacs 20.7 with Mule-UCS has the
;; Unicode machinery it relies on (decode-char and encode-char with the
;; ucs charset), but lacks a handful of Emacs 21 functions.  Each is
;; defined here only when missing, so this file is harmless on later
;; Emacsen.

(or (fboundp 'replace-regexp-in-string)
    (defun replace-regexp-in-string (regexp rep string &optional fixedcase literal subexp start)
      "Emacs 21's replace-regexp-in-string."
      (let ((l (length string)) (start (or start 0)) matches str mb me)
        (save-match-data
          (while (and (< start l) (string-match regexp string start))
            (setq mb (match-beginning 0) me (match-end 0))
            (when (= me mb) (setq me (min l (1+ mb))))
            (string-match regexp (setq str (substring string mb me)))
            (setq matches (cons (replace-match (if (stringp rep) rep (funcall rep (match-string 0 str))) fixedcase literal str subexp)
                                (cons (substring string start mb) matches)))
            (setq start me))
          (setq matches (cons (substring string start l) matches))
          (apply 'concat (nreverse matches))))))

(or (fboundp 'propertize)
    (defun propertize (string &rest properties)
      "Emacs 21's propertize."
      (let ((s (copy-sequence string)))
        (add-text-properties 0 (length s) properties s)
        s)))


;; Emacs 20 has no hash tables.  nxml-mode keeps a few, with eq or equal
;; keys; an alist inside a marked vector stands in for them.  Lookups are
;; linear, which is slow for a large schema but correct.
(or (fboundp 'make-hash-table)
    (progn
      (defun make-hash-table (&rest args)
	"Emacs 21's make-hash-table, reduced to :test."
	(let ((test (or (cadr (memq :test args)) 'eql)))
	  (vector 'nxml-e20-hash-table test nil)))
      (defun hash-table-p (x)
	(and (vectorp x) (= (length x) 3) (eq (aref x 0) 'nxml-e20-hash-table)))
      (defun nxml-e20-hash-assoc (key table)
	(let ((test (aref table 1)) (l (aref table 2)))
	  (cond ((eq test 'eq) (assq key l))
		((eq test 'equal) (assoc key l))
		(t (while (and l (not (eql (car (car l)) key))) (setq l (cdr l)))
		   (car l)))))
      (defun gethash (key table &optional dflt)
	(let ((c (nxml-e20-hash-assoc key table))) (if c (cdr c) dflt)))
      (defun puthash (key value table)
	(let ((c (nxml-e20-hash-assoc key table)))
	  (if c (setcdr c value)
	    (aset table 2 (cons (cons key value) (aref table 2))))
	  value))
      (defun remhash (key table)
	(let ((c (nxml-e20-hash-assoc key table)))
	  (when c (aset table 2 (delq c (aref table 2))))
	  nil))
      (defun clrhash (table) (aset table 2 nil) table)
      (defun hash-table-count (table) (length (aref table 2)))
      (defun maphash (fn table)
	(let ((l (aref table 2)))
	  (while l (funcall fn (car (car l)) (cdr (car l))) (setq l (cdr l)))))))

;; Emacs 21 fontifies lazily from redisplay through fontification-functions.
;; Emacs 20 has no such hook, so fontify what is on screen after each
;; command instead, the way lazy-lock did.
(unless (boundp 'fontification-functions)
  (defvar fontification-functions nil
    "Stand-in for Emacs 21's variable; run from post-command-hook on Emacs 20.")
  (defun nxml-e20-fontify-window ()
    (when (and fontification-functions (not (window-minibuffer-p)))
      (let ((start (window-start)) (end (window-end nil t)) pos)
	(save-excursion
	  (setq pos (if (get-text-property start 'fontified)
			(next-single-property-change start 'fontified nil end)
		      start))
	  (while (and pos (< pos end))
	    (run-hook-with-args 'fontification-functions pos)
	    (setq pos (next-single-property-change pos 'fontified nil end))
	    (while (and pos (< pos end) (not (get-text-property pos 'fontified)))
	      (run-hook-with-args 'fontification-functions pos)
	      (setq pos (next-single-property-change pos 'fontified nil end))))))))
  (add-hook 'post-command-hook 'nxml-e20-fontify-window))

;; Emacs 20's regexp engine has no shy groups \(?:...\), no interval
;; operators \{n,m\} and no [:alpha:]-style classes; nxml-mode's regexps
;; use all three.  Rather than rewrite forty regexps by hand, translate
;; them when they are used: shy groups become numbered groups, intervals
;; are unrolled, classes become the ASCII characters they stand for (plus
;; everything non-ASCII), and afterwards the match data is put back into
;; the numbering the caller expects.  Only regexps that contain one of
;; those constructs are touched, so the rest of Emacs is unaffected.
(unless (string-match "a\\(?:b\\)c" "abc")
  (require 'advice)
  (defconst nxml-e20-class-alist
    '(("[:alpha:]" . "a-zA-Z\\200-\\377") ("[:alnum:]" . "0-9a-zA-Z\\200-\\377")
      ("[:digit:]" . "0-9") ("[:xdigit:]" . "0-9a-fA-F") ("[:space:]" . " \t\n\r\f")
      ("[:upper:]" . "A-Z") ("[:lower:]" . "a-z") ("[:nonascii:]" . "\\200-\\377")
      ("[:blank:]" . " \t")))
  (defvar nxml-e20-regexp-cache nil)
  (defun nxml-e20-translate (re)
    "Return (TRANSLATED . GROUPS); GROUPS lists, per output group, the
original group number or nil for a shy group."
    (let ((i 0) (n (length re)) (out nil) (groups nil) (orig 0)
	  (atoms nil))		; stack of output positions where atoms start
      (while (< i n)
	(let ((c (aref re i)))
	  (cond
	   ((and (eq c ?\\) (< (1+ i) n))
	    (let ((d (aref re (1+ i))))
	      (cond
	       ((eq d ?\()
		(setq atoms (cons (length out) atoms))
		(if (and (< (+ i 3) n) (eq (aref re (+ i 2)) ??) (eq (aref re (+ i 3)) ?:))
		    (progn (setq groups (cons nil groups)) (setq out (cons "\\(" out)) (setq i (+ i 4)))
		  (setq orig (1+ orig)) (setq groups (cons orig groups))
		  (setq out (cons "\\(" out)) (setq i (+ i 2))))
	       ((eq d ?\))
		;; keep the atom start of the group for a following interval
		(let ((start (car atoms))) (setq atoms (cdr atoms))
		  (setq out (cons "\\)" out)) (setq i (+ i 2))
		  (setq atoms (cons (cons 'group start) atoms))))
	       ((eq d ?{)
		(let* ((j (+ i 2)) (k (string-match "\\\\}" re j))
		       (spec (substring re j k)) lo hi
		       (a (car atoms)) atom rest)
		  (setq atoms (cdr atoms))
		  (setq a (if (consp a) (cdr a) a))
		  ;; atom = everything emitted since position a
		  (let ((all (apply 'concat (reverse out))))
		    (setq atom (substring all a)) (setq rest (substring all 0 a)))
		  (if (string-match "," spec)
		      (setq lo (string-to-int (substring spec 0 (match-beginning 0)))
			    hi (if (= (match-end 0) (length spec)) nil
				 (string-to-int (substring spec (match-end 0)))))
		    (setq lo (string-to-int spec) hi lo))
		  (let ((rep "") (m 0))
		    (while (< m lo) (setq rep (concat rep atom)) (setq m (1+ m)))
		    (cond ((null hi) (setq rep (concat rep atom "*")))
			  (t (while (< m hi) (setq rep (concat rep atom "?")) (setq m (1+ m)))))
		    (setq out (list (concat rest rep))))
		  (setq i (+ k 2))))
	       (t (setq atoms (cons (length (apply 'concat (reverse out))) atoms))
		  (setq out (cons (substring re i (+ i 2)) out)) (setq i (+ i 2))))))
	   ((eq c ?\[)
	    ;; copy a bracket expression, expanding [:class:] inside it
	    (let ((j (1+ i)) (buf "["))
	      (when (and (< j n) (eq (aref re j) ?^)) (setq buf "[^") (setq j (1+ j)))
	      (when (and (< j n) (eq (aref re j) ?\])) (setq buf (concat buf "]")) (setq j (1+ j)))
	      (while (and (< j n) (not (eq (aref re j) ?\])))
		(if (and (eq (aref re j) ?\[) (< (1+ j) n) (eq (aref re (1+ j)) ?:))
		    (let* ((e (string-match ":\\]" re j)) (cls (substring re j (+ e 2))))
		      (setq buf (concat buf (or (cdr (assoc cls nxml-e20-class-alist)) (error "no class %s" cls))))
		      (setq j (+ e 2)))
		  (setq buf (concat buf (char-to-string (aref re j)))) (setq j (1+ j))))
	      (setq atoms (cons (length (apply 'concat (reverse out))) atoms))
	      (setq out (cons (concat buf "]") out)) (setq i (1+ j))))
	   (t (setq atoms (cons (length (apply 'concat (reverse out))) atoms))
	      (setq out (cons (char-to-string c) out)) (setq i (1+ i))))))
      (cons (apply 'concat (reverse out)) (nreverse groups))))
  (defun nxml-e20-needs-translation-p (re)
    (or (string-match "\\\\(\\?:\\|\\\\{\\|\\[:[a-z]+:\\]" re)))
  (defun nxml-e20-regexp (re)
    (or (cdr (assoc re nxml-e20-regexp-cache))
	(let ((tr (nxml-e20-translate re)))
	  (setq nxml-e20-regexp-cache (cons (cons re tr) nxml-e20-regexp-cache))
	  tr)))
  (defun nxml-e20-fix-match-data (groups)
    "Rebuild the match data so group N is the caller's group N."
    (let* ((md (match-data)) (max 0) (g groups) out (k 1))
      (while g (if (car g) (setq max (car g))) (setq g (cdr g)))
      (setq out (make-vector (* 2 (1+ max)) nil))
      (aset out 0 (nth 0 md)) (aset out 1 (nth 1 md))
      (while groups
	(when (car groups)
	  (aset out (* 2 (car groups)) (nth (* 2 k) md))
	  (aset out (1+ (* 2 (car groups))) (nth (1+ (* 2 k)) md)))
	(setq k (1+ k) groups (cdr groups)))
      (set-match-data (append out nil))))
  (defvar nxml-e20-translating nil)
  (defmacro nxml-e20-advise (fn)
    `(defadvice ,fn (around nxml-e20 activate)
       (if (and (not nxml-e20-translating) (stringp (ad-get-arg 0))
		(let ((nxml-e20-translating t)) (nxml-e20-needs-translation-p (ad-get-arg 0))))
	   (let ((tr (let ((nxml-e20-translating t)) (nxml-e20-regexp (ad-get-arg 0)))))
	     (ad-set-arg 0 (car tr))
	     ad-do-it
	     (when ad-return-value (nxml-e20-fix-match-data (cdr tr))))
	 ad-do-it)))
  (nxml-e20-advise string-match)
  (nxml-e20-advise looking-at)
  (nxml-e20-advise re-search-forward)
  (nxml-e20-advise re-search-backward))

(or (fboundp 'restore-buffer-modified-p)
    (defalias 'restore-buffer-modified-p 'set-buffer-modified-p))

(or (fboundp 'nbutlast)
    (defun nbutlast (list &optional n)
      "Emacs 21's nbutlast."
      (let ((m (length list)))
	(or n (setq n 1))
	(and (< n m)
	     (progn (if (> n 0) (setcdr (nthcdr (- (1- m) n) list) nil)) list)))))
(or (fboundp 'butlast)
    (defun butlast (list &optional n) (if (and n (<= n 0)) list (nbutlast (copy-sequence list) n))))

(provide (quote nxml-e20))
