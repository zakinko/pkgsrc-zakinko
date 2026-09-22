;;; emacs-compat.el --- what Emacs 21 to 23 lack

;; Elisp written for Emacs 24 and later reaches for things the older
;; Emacsen in pkgsrc do not have.  Emacs 21.4 has none of them; 22.3 and
;; 23.4 grew dolist and delete-dups but not the rest; 24.5 and later have
;; everything here and load this file as a no-op.

;; Each definition is guarded, so one file serves every version.  For
;; Emacs 20 use devel/emacs20-compat, which has more to do: this file
;; assumes a reader that takes #x and ?\s.

;;; Code:

(unless (fboundp 'defvar-local)
  (defmacro defvar-local (symbol value &optional docstring)
    "Define SYMBOL as a buffer-local variable with VALUE as its default."
    (list 'progn (list 'defvar symbol value docstring)
	  (list 'make-variable-buffer-local (list 'quote symbol)))))

(unless (fboundp 'alist-get)
  (defun alist-get (key alist &optional default remove testfn)
    "Return the value associated with KEY in ALIST, or DEFAULT.
REMOVE is accepted and ignored; it only matters to setf."
    (let ((x (if testfn
		 (assoc key alist testfn)
	       (assq key alist))))
      (if x (cdr x) default))))

(unless (fboundp 'string-trim)
  (defun string-trim (string &optional trim-left trim-right)
    "Trim whitespace from both ends of STRING."
    (let ((s string))
      (when (string-match (concat "\\`\\(?:" (or trim-left "[ \t\n\r]+") "\\)") s)
	(setq s (substring s (match-end 0))))
      (when (string-match (concat "\\(?:" (or trim-right "[ \t\n\r]+") "\\)\\'") s)
	(setq s (substring s 0 (match-beginning 0))))
      s)))

(unless (fboundp 'string-empty-p)
  (defun string-empty-p (string)
    "Return non-nil if STRING is the empty string."
    (string= string "")))

(unless (fboundp 'when-let)
  (defmacro when-let (spec &rest body)
    "Bind the variables in SPEC and evaluate BODY if all the values are non-nil."
    (let ((bindings (if (and (consp spec) (symbolp (car spec)))
			(list spec)
		      spec)))
      (if (null bindings)
	  (cons 'progn body)
	(let ((b (car bindings)))
	  (list 'let (list b)
		(list 'when (car b)
		      (append (list 'when-let (cdr bindings)) body))))))))

(unless (fboundp 'seq-filter)
  (defun seq-filter (pred sequence)
    "Return a list of the elements of SEQUENCE for which PRED is non-nil."
    (let (out)
      (mapc (lambda (x) (when (funcall pred x) (setq out (cons x out))))
	    (append sequence nil))
      (nreverse out))))

(unless (fboundp 'dolist)
  (defmacro dolist (spec &rest body)
    "Loop over a list, binding the car of SPEC to each element."
    (let ((var (car spec)) (lst (make-symbol "lst")))
      (list 'let (list (list lst (nth 1 spec)) (list var nil))
	    (append (list 'while lst
			  (list 'setq var (list 'car lst)))
		    body
		    (list (list 'setq lst (list 'cdr lst))))
	    (nth 2 spec)))))

(unless (fboundp 'delete-dups)
  (defun delete-dups (list)
    "Destructively remove `equal' duplicates from LIST."
    (let ((tail list))
      (while tail
	(setcdr tail (delete (car tail) (cdr tail)))
	(setq tail (cdr tail))))
    list))

(provide 'emacs-compat)

;;; emacs-compat.el ends here
