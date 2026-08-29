;;; site-start.el --- load what pkgsrc packages left in site-start.d

;; Emacs loads this file at startup, before ~/.emacs, because site-run-file
;; is "site-start" and this directory is on load-path.  A package that needs
;; autoloads registered installs share/emacs/site-lisp/site-start.d/NN-name.el
;; and this loads them, in name order, so NN can express ordering.
;;
;; A broken file must not stop Emacs from starting, so each load is wrapped.
;; The message goes to *Messages*, which is where the user will look.
;;
;; Written for the oldest Emacs pkgsrc still carries (20.7), so: no dolist,
;; no cl, no lexical binding.

(let* ((site-start-d
	(expand-file-name "site-start.d"
			  (file-name-directory load-file-name)))
       (site-start-files
	(and (file-directory-p site-start-d)
	     (sort (directory-files site-start-d t "\\.elc?\\'") 'string<)))
       (site-start-seen nil))
  (while site-start-files
    (let ((f (car site-start-files)))
      ;; .el と .elc が両方在れば load に選ばせる。拡張子を落として渡す。
      (setq f (if (string-match "\\.elc?\\'" f) (substring f 0 (match-beginning 0)) f))
      (if (member f site-start-seen)
	  nil
	(setq site-start-seen (cons f site-start-seen))
	(condition-case site-start-err
	    (load f nil t)
	  (error
	   (message "site-start.d: %s: %s" f
		    (if (fboundp 'error-message-string)
			(error-message-string site-start-err)
		      (prin1-to-string site-start-err)))))))
    (setq site-start-files (cdr site-start-files))))
