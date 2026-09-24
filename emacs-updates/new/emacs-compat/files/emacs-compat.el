;;; emacs-compat.el --- what an older Emacs lacks  -*- coding: iso-2022-7bit -*-

;; pkgsrc still carries editors/emacs20, and some of the elisp it packages
;; was written for Emacs 21 or later.  This file defines, only when they
;; are missing, the functions, macros and mechanisms those packages use:
;; hash tables (over alists), replace-regexp-in-string, propertize,
;; nbutlast, subr-x's string functions, setq-local, with-eval-after-load,
;; prog-mode, syntax-ppss, syntax-propertize, and a regexp translator for
;; shy groups, \{n,m\} and [:alpha:] classes, which Emacs 20's engine
;; does not have.  It is harmless on later Emacsen, where everything here
;; already exists.  Emacs-20-only quirks that belong to one package (how
;; nxml-mode fontifies, say) stay with that package.

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
	  (vector 'e20-hash-table test nil)))
      (defun hash-table-p (x)
	(and (vectorp x) (= (length x) 3) (eq (aref x 0) 'e20-hash-table)))
      (defun e20-hash-assoc (key table)
	(let ((test (aref table 1)) (l (aref table 2)))
	  (cond ((eq test 'eq) (assq key l))
		((eq test 'equal) (assoc key l))
		(t (while (and l (not (eql (car (car l)) key))) (setq l (cdr l)))
		   (car l)))))
      (defun gethash (key table &optional dflt)
	(let ((c (e20-hash-assoc key table))) (if c (cdr c) dflt)))
      (defun puthash (key value table)
	(let ((c (e20-hash-assoc key table)))
	  (if c (setcdr c value)
	    (aset table 2 (cons (cons key value) (aref table 2))))
	  value))
      (defun remhash (key table)
	(let ((c (e20-hash-assoc key table)))
	  (when c (aset table 2 (delq c (aref table 2))))
	  nil))
      (defun clrhash (table) (aset table 2 nil) table)
      (defun hash-table-count (table) (length (aref table 2)))
      (defun maphash (fn table)
	(let ((l (aref table 2)))
	  (while l (funcall fn (car (car l)) (cdr (car l))) (setq l (cdr l)))))))

;; Emacs 20's regexp engine has no shy groups \(?:...\), no interval
;; operators \{n,m\} and no [:alpha:]-style classes; nxml-mode's regexps
;; use all three.  Rather than rewrite forty regexps by hand, translate
;; them when they are used: shy groups become numbered groups, intervals
;; are unrolled, classes become the ASCII characters they stand for (plus
;; everything non-ASCII), and afterwards the match data is put back into
;; the numbering the caller expects.  Only regexps that contain one of
;; those constructs are touched, so the rest of Emacs is unaffected.
(unless (condition-case nil (string-match "a\\(?:b\\)c" "abc") (error nil))
  (require 'advice)
  (defconst e20-class-alist
    '(("[:alpha:]" . "a-zA-Z\\200-\\377") ("[:alnum:]" . "0-9a-zA-Z\\200-\\377")
      ("[:digit:]" . "0-9") ("[:xdigit:]" . "0-9a-fA-F") ("[:space:]" . " \t\n\r\f")
      ("[:upper:]" . "A-Z") ("[:lower:]" . "a-z") ("[:nonascii:]" . "\\200-\\377")
      ("[:blank:]" . " \t")))
  (defvar e20-regexp-cache nil)
  (defun e20-translate (re)
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
	       ((and (eq d ?_) (< (+ i 2) n) (memq (aref re (+ i 2)) '(?< ?>)))
		;; symbol boundaries (22): word boundaries are the nearest thing
		(setq atoms (cons (length (apply 'concat (reverse out))) atoms))
		(setq out (cons (concat "\\" (char-to-string (aref re (+ i 2)))) out)) (setq i (+ i 3)))
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
		      (setq buf (concat buf (or (cdr (assoc cls e20-class-alist)) (error "no class %s" cls))))
		      (setq j (+ e 2)))
		  (setq buf (concat buf (char-to-string (aref re j)))) (setq j (1+ j))))
	      (setq atoms (cons (length (apply 'concat (reverse out))) atoms))
	      (setq out (cons (concat buf "]") out)) (setq i (1+ j))))
	   (t (setq atoms (cons (length (apply 'concat (reverse out))) atoms))
	      (setq out (cons (char-to-string c) out)) (setq i (1+ i))))))
      (cons (apply 'concat (reverse out)) (nreverse groups))))
  (defun e20-needs-translation-p (re)
    (or (string-match "\\\\(\\?:\\|\\\\{\\|\\[:[a-z]+:\\]\\|\\\\_[<>]" re)))
  (defun e20-regexp (re)
    (or (cdr (assoc re e20-regexp-cache))
	(let ((tr (e20-translate re)))
	  (setq e20-regexp-cache (cons (cons re tr) e20-regexp-cache))
	  tr)))
  (defun e20-fix-match-data (groups)
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
  (defvar e20-translating nil)
  (defmacro e20-advise (fn)
    `(defadvice ,fn (around e20 activate)
       (if (and (not e20-translating) (stringp (ad-get-arg 0))
		(let ((e20-translating t)) (e20-needs-translation-p (ad-get-arg 0))))
	   (let ((tr (let ((e20-translating t)) (e20-regexp (ad-get-arg 0)))))
	     (ad-set-arg 0 (car tr))
	     ad-do-it
	     (when ad-return-value (e20-fix-match-data (cdr tr))))
	 ad-do-it)))
  (e20-advise string-match)
  (e20-advise looking-at)
  (e20-advise re-search-forward)
  (e20-advise re-search-backward))

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

;;; subr-x (24.4)
(or (fboundp 'string-trim)
    (defun string-trim (s)
      (if (string-match "\\`[ \t\n\r]+" s) (setq s (substring s (match-end 0))))
      (if (string-match "[ \t\n\r]+\\'" s) (setq s (substring s 0 (match-beginning 0))))
      s))
(or (fboundp 'string-join)
    (defun string-join (l &optional sep) (mapconcat 'identity l (or sep ""))))
(or (fboundp 'string-empty-p) (defun string-empty-p (s) (string= s "")))
(or (fboundp 'when-let)
    (defmacro when-let (spec &rest body)
      (let ((v (if (consp (car spec)) (car spec) spec)))
	(list 'let (list (list (car v) (car (cdr v))))
	      (cons 'when (cons (car v) body))))))
(or (fboundp 'if-let)
    (defmacro if-let (spec then &rest else)
      (let ((v (if (consp (car spec)) (car spec) spec)))
	(list 'let (list (list (car v) (car (cdr v))))
	      (cons 'if (cons (car v) (cons then else)))))))
(provide 'subr-x)

;;; cl and obsolescence, so that a package need not pull in APEL
;; devel/apel is marked incompatible with emacs20, so the poe it used to
;; supply is out of reach here.  These are the three things poe was wanted
;; for: dolist, cl's remove, and the WHEN argument make-obsolete-variable
;; grew in Emacs 23.
(or (fboundp 'dolist)
    (defmacro dolist (spec &rest body)
      (let ((var (car spec)) (lst (make-symbol "lst")))
	(list 'let (list (list lst (car (cdr spec))) (list var nil))
	      (list 'while lst
		    (list 'setq var (list 'car lst))
		    (cons 'progn body)
		    (list 'setq lst (list 'cdr lst)))
	      (car (cdr (cdr spec)))))))
(or (fboundp 'remove)
    (defun remove (item seq)
      "Return a copy of SEQ with all `equal' occurrences of ITEM removed."
      (delete item (copy-sequence seq))))
;; Emacs 20 takes two arguments and errors on a third.
(or (condition-case nil
	(progn (make-obsolete-variable 'e20-compat--probe nil "1.0") t)
      (error nil))
    (progn
      ;; Emacs 20 has no lexical binding, so the original has to be kept
      ;; under a name rather than closed over.
      (defalias 'e20-make-obsolete-variable
	(symbol-function 'make-obsolete-variable))
      (defun make-obsolete-variable (obsolete-name current-name
				     &optional when access-type)
	"Make the byte compiler warn that OBSOLETE-NAME is obsolete.
WHEN and ACCESS-TYPE are accepted for Emacs 23 compatibility and ignored."
	(e20-make-obsolete-variable obsolete-name current-name))))

;;; assorted functions from 22 to 26
(or (fboundp 'file-local-name)
    (defun file-local-name (file)
      "Return the local name of FILE (no remote files on Emacs 20)."
      file))
(or (fboundp 'string-prefix-p)
    (defun string-prefix-p (prefix string &optional ignore-case)
      (let ((l (length prefix)))
	(and (<= l (length string))
	     (eq t (compare-strings prefix 0 l string 0 l ignore-case))))))
(or (fboundp 'string-suffix-p)
    (defun string-suffix-p (suffix string &optional ignore-case)
      (let ((sl (length string)) (l (length suffix)))
	(and (<= l sl)
	     (eq t (compare-strings suffix 0 l string (- sl l) sl ignore-case))))))
(or (fboundp 'read-shell-command)
    (defun read-shell-command (prompt &optional initial hist &rest args)
      (read-string prompt initial hist)))
(or (fboundp 'process-lines)
    (defun process-lines (program &rest args)
      (with-temp-buffer
	(apply 'call-process program nil (current-buffer) nil args)
	(split-string (buffer-string) "\n" t))))

;; 26; quoted file names do not exist before it
(or (fboundp 'file-name-unquote) (defun file-name-unquote (name) name))
(or (fboundp 'file-name-quote) (defun file-name-quote (name) name))
(or (fboundp 'use-region-p)
    (defun use-region-p () (and mark-active (> (region-end) (region-beginning)))))
(or (fboundp 'with-selected-window)
    (defmacro with-selected-window (window &rest body)
      (list 'let '((e20-old-window (selected-window)))
	    (list 'unwind-protect
		  (cons 'progn (cons (list 'select-window window) body))
		  '(select-window e20-old-window)))))

;; 22: split-string's OMIT-NULLS (Emacs 20's always omits nulls)
(if (and (not (fboundp 'e20-split-string))
	 (condition-case nil (progn (split-string "a" "b" t) nil) (error t)))
    (progn
      (fset 'e20-split-string (symbol-function 'split-string))
      (defun split-string (string &optional separators omit-nulls trim)
	(e20-split-string string separators))))

;;; setq-local, defvar-local (24.3)
(or (fboundp 'setq-local)
    (defmacro setq-local (var val)
      (list 'set (list 'make-local-variable (list 'quote var)) val)))
(or (fboundp 'defvar-local)
    (defmacro defvar-local (var val &optional doc)
      (list 'progn (list 'defvar var val doc)
	    (list 'make-variable-buffer-local (list 'quote var)))))

;;; with-eval-after-load (24.4)
(or (fboundp 'with-eval-after-load)
    (defmacro with-eval-after-load (file &rest body)
      (list 'eval-after-load file (list 'quote (cons 'progn body)))))

;;; user-error (24.3)
(or (fboundp 'user-error)
    (defun user-error (format &rest args) (apply 'error format args)))

;;; prog-mode (24.1): a plain parent mode
(or (fboundp 'prog-mode)
    (progn
      (defvar prog-mode-map (make-sparse-keymap))
      (defvar prog-mode-hook nil)
      (defvar prog-mode-syntax-table (make-syntax-table))
      (defvar prog-mode-abbrev-table nil)
      (define-derived-mode prog-mode fundamental-mode "Prog"
	"Major mode for editing programming language source code.")))

;;; syntax-ppss (21)
(or (fboundp 'syntax-ppss)
    (defun syntax-ppss (&optional pos)
      "Parse-Partial-Sexp State at POS, defaulting to point."
      (save-excursion (parse-partial-sexp (point-min) (or pos (point))))))

;;; syntax-propertize (24.1), on top of the syntax-table text property that
;;; Emacs 20 already has.  The rules become a function that scans a region;
;;; it is run over the whole buffer after a change, from post-command-hook,
;;; since nothing in Emacs 20 calls it lazily.
(unless (fboundp 'syntax-propertize)
  (defvar syntax-propertize-function nil)
  (make-variable-buffer-local 'syntax-propertize-function)
  (defvar syntax-propertize--done -1)
  (make-variable-buffer-local 'syntax-propertize--done)
  (defconst e20-syntax-codes
    '((?\  . 0) (?- . 0) (?. . 1) (?w . 2) (?_ . 3) (?\( . 4) (?\) . 5) (?\' . 6)
      (?\" . 7) (?$ . 8) (?\\ . 9) (?/ . 10) (?< . 11) (?> . 12) (?@ . 13)
      (?! . 14) (?| . 15)))
  (or (fboundp 'string-to-syntax)
      (defun string-to-syntax (string)
	"Convert a syntax descriptor STRING into a raw syntax descriptor."
	(let ((code (cdr (assq (aref string 0) e20-syntax-codes)))
	      (matching (if (and (> (length string) 1) (not (eq (aref string 1) ?\ )))
			    (aref string 1)))
	      (i 2))
	  (while (< i (length string))
	    (let ((c (aref string i)))
	      (setq code (logior code
				 (cond ((eq c ?1) (lsh 1 16)) ((eq c ?2) (lsh 1 17))
				       ((eq c ?3) (lsh 1 18)) ((eq c ?4) (lsh 1 19))
				       ((eq c ?p) (lsh 1 20)) ((eq c ?b) (lsh 1 21))
				       ((eq c ?n) (lsh 1 22)) (t 0)))))
	    (setq i (1+ i)))
	  (cons code matching))))
  (defvar e20-syntax-propertize-rules nil
    "Alist of the functions made by `syntax-propertize-rules' to their rules.")
  (defun e20-syntax-propertize-make (rules)
    "Return a function of (START END) applying RULES' syntax-table properties,
and remember the rules, so font-lock can be told about them too."
    (let ((fn (list 'lambda '(start end)
		    (list 'let '((case-fold-search nil))
			  (cons 'progn
				(mapcar
				 (lambda (rule)
				   (list 'progn
					 '(goto-char start)
					 (list 'while (list 're-search-forward (car rule) 'end t)
					       (cons 'progn
						     (mapcar
						      (lambda (act)
							(list 'if (list 'match-beginning (car act))
							      (list 'put-text-property
								    (list 'match-beginning (car act))
								    (list 'match-end (car act))
								    ''syntax-table
								    (list 'string-to-syntax (car (cdr act))))))
						      (cdr rule))))))
				 rules))))))
      (setq e20-syntax-propertize-rules (cons (cons fn rules) e20-syntax-propertize-rules))
      fn))
  (defmacro syntax-propertize-rules (&rest rules)
    "Return a function of (START END) that applies RULES' syntax-table properties."
    (list 'e20-syntax-propertize-make (list 'quote rules)))
  (defun e20-syntactic-keywords (fn)
    "The rules behind FN as Emacs 20 `font-lock-syntactic-keywords'."
    (let ((rules (cdr (assq fn e20-syntax-propertize-rules))))
      (mapcar (lambda (rule)
		(cons (car rule)
		      (mapcar (lambda (act)
				(list (car act) (list 'string-to-syntax (car (cdr act))) t))
			      (cdr rule))))
	      rules)))
  (defun syntax-propertize (pos)
    "Ensure syntax-table properties are set up to POS (the whole buffer here)."
    (when (and syntax-propertize-function (< syntax-propertize--done (point-max)))
      (setq parse-sexp-lookup-properties t)
      ;; Emacs 20's font-lock removes and re-adds syntax-table properties
      ;; itself, from font-lock-syntactic-keywords; hand it the same rules
      (when (and (not (and (boundp 'font-lock-syntactic-keywords) font-lock-syntactic-keywords))
		 (assq syntax-propertize-function e20-syntax-propertize-rules))
	(set (make-local-variable 'font-lock-syntactic-keywords)
	     (e20-syntactic-keywords syntax-propertize-function)))
      (let ((inhibit-read-only t) (buffer-undo-list t)
	    (modified (buffer-modified-p))
	    (after-change-functions nil) (before-change-functions nil))
	(save-excursion
	  (save-restriction
	    (widen)
	    (remove-text-properties (point-min) (point-max) '(syntax-table nil))
	    (funcall syntax-propertize-function (point-min) (point-max))))
	(set-buffer-modified-p modified)
	(setq syntax-propertize--done (point-max)))))
  (defun e20-after-change (beg end len)
    (setq syntax-propertize--done -1))
  (defun e20-propertize-maybe ()
    (when syntax-propertize-function
      (setq parse-sexp-lookup-properties t)
      (syntax-propertize (point-max))))
  (add-hook 'after-change-functions 'e20-after-change)
  (add-hook 'post-command-hook 'e20-propertize-maybe))


;;; regexp-opt's PAREN = words (21)
(if (and (not (fboundp 'e20-regexp-opt))
	 (not (string-match "\\\\<" (progn (require 'regexp-opt) (regexp-opt '("a") 'words)))))
    (progn
      (fset 'e20-regexp-opt (symbol-function 'regexp-opt))
      (defun regexp-opt (strings &optional paren)
	(if (memq paren '(words symbols))
	    (concat "\\<" (e20-regexp-opt strings t) "\\>")
	  (e20-regexp-opt strings paren)))))

;;; set-process-query-on-exit-flag (22)
(or (fboundp 'set-process-query-on-exit-flag)
    (defun set-process-query-on-exit-flag (process flag)
      (process-kill-without-query process (not flag))))
(or (fboundp 'process-query-on-exit-flag)
    (defun process-query-on-exit-flag (process) t))

;;; obarray-make (25)
(or (fboundp 'obarray-make)
    (defun obarray-make (&optional size) (make-vector (or size 59) 0)))
(or (fboundp 'obarrayp)
    (defun obarrayp (o) (and (vectorp o) (> (length o) 0))))

;;; looking-back (22)
(or (fboundp 'looking-back)
    (defun looking-back (regexp &optional limit greedy)
      (save-excursion
	(re-search-backward (concat "\\(?:" regexp "\\)\\=") limit t))))

;; The three that Emacs 24 added.  They came from the file that
;; served Emacs 21 to 23, when the two compat packages became one.
;; Guarded like everything else here, so they do nothing on an
;; Emacs that already has them.

(unless (fboundp 'alist-get)
  (defun alist-get (key alist &optional default remove testfn)
    "Return the value associated with KEY in ALIST, or DEFAULT.
REMOVE is accepted and ignored; it only matters to setf."
    (let ((x (if testfn
		 (assoc key alist testfn)
	       (assq key alist))))
      (if x (cdr x) default))))

(unless (fboundp 'seq-filter)
  (defun seq-filter (pred sequence)
    "Return a list of the elements of SEQUENCE for which PRED is non-nil."
    (let (out)
      (mapc (lambda (x) (when (funcall pred x) (setq out (cons x out))))
	    (append sequence nil))
      (nreverse out))))

(unless (fboundp 'delete-dups)
  (defun delete-dups (list)
    "Destructively remove `equal' duplicates from LIST."
    (let ((tail list))
      (while tail
	(setcdr tail (delete (car tail) (cdr tail)))
	(setq tail (cdr tail))))
    list))

(provide 'e20-compat)
(provide 'emacs-compat)
