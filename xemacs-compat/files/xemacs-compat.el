;;; xemacs-compat.el --- what XEmacs 21.4 and 21.5 lack

;; Elisp written for GNU Emacs 24 and later reaches for a handful of
;; things XEmacs never grew.  Each is defined here only when it is
;; missing, so the same file serves 21.4 and 21.5 -- they differ in one
;; entry, delete-dups, which 21.5 has and 21.4 does not.

;;; Code:

;; eval took a LEXICAL argument in Emacs 24.  XEmacs has the one-argument
;; form, so a caller that passes t (dash.el does) gets a wrong-number-of-
;; arguments error at byte-compile time.  XEmacs has no lexical binding to
;; turn on, so the argument is accepted and ignored.
(unless (condition-case nil (progn (eval 1 t) t) (error nil))
  (defalias 'xemacs-compat-original-eval (symbol-function 'eval))
  (defun eval (form &optional lexical)
    "Evaluate FORM and return its value.
LEXICAL is accepted for GNU Emacs 24 compatibility and ignored: XEmacs
has no lexical binding to select."
    (xemacs-compat-original-eval form)))

(unless (fboundp 'delete-dups)
  (defun delete-dups (list)
    "Destructively remove `equal' duplicates from LIST."
    (let ((tail list))
      (while tail
	(setcdr tail (delete (car tail) (cdr tail)))
	(setq tail (cdr tail))))
    list))

(unless (fboundp 'defvar-local)
  (defmacro defvar-local (symbol value &optional docstring)
    "Define SYMBOL as a buffer-local variable with VALUE as its default."
    (list 'progn (list 'defvar symbol value docstring)
	  (list 'make-variable-buffer-local (list 'quote symbol)))))

(unless (fboundp 'alist-get)
  (defun alist-get (key alist &optional default remove)
    "Find the first element of ALIST whose car equals KEY and return its cdr."
    (let ((x (assq key alist)))
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

;; A package that generates its own autoloads calls GNU Emacs's
;; batch-update-directory.  XEmacs does the same job under a longer name,
;; so the build dies with a void function before it compiles anything.
(unless (fboundp 'batch-update-directory)
  (require 'autoload)
  (when (fboundp 'batch-update-directory-autoloads)
    (defalias 'batch-update-directory 'batch-update-directory-autoloads)))

(provide 'xemacs-compat)

;;; xemacs-compat.el ends here
