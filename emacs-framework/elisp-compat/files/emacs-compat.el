;;; emacs-compat.el --- the old name for elisp-compat

;; devel/elisp-compat replaced devel/emacs-compat.  Code in the tree still says
;; (require 'emacs-compat), and a provide inside elisp-compat.el cannot satisfy
;; that: require looks for a file of this name.  So this file exists to
;; be found, and pulls in the real one.

(require 'elisp-compat)

(provide 'emacs-compat)

;;; emacs-compat.el ends here
