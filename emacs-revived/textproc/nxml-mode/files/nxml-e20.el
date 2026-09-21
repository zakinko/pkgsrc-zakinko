;;; nxml-e20.el --- nxml-mode's fontification on Emacs 20  -*- coding: iso-2022-7bit -*-

;; Everything general nxml-mode needs from later Emacsen comes from
;; e20-compat.el (devel/emacs20-compat).  What is left is nxml-mode's own
;; way of fontifying.

(require 'e20-compat)

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


(provide 'nxml-e20)
