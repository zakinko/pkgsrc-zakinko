;;; 20-calc.el --- register calc's entry points

;; calc installs into site-lisp/calc, which subdirs.el already puts on
;; load-path, but nothing declares its commands.  Without these autoloads
;; M-x calc does not exist and the package cannot be used at all; the old
;; MESSAGE asked the user to paste them into ~/.emacs by hand.

(autoload 'calc-dispatch	   "calc" "Calculator Options" t)
(autoload 'full-calc		   "calc" "Full-screen Calculator" t)
(autoload 'full-calc-keypad	   "calc" "Full-screen X Calculator" t)
(autoload 'calc-eval		   "calc" "Use Calculator from Lisp")
(autoload 'defmath		   "calc" nil t t)
(autoload 'calc			   "calc" "Calculator Mode" t)
(autoload 'quick-calc		   "calc" "Quick Calculator" t)
(autoload 'calc-keypad		   "calc" "X windows Calculator" t)
(autoload 'calc-embedded	   "calc" "Use Calc inside any buffer" t)
(autoload 'calc-embedded-activate  "calc" "Activate =>'s in buffer" t)
(autoload 'calc-grab-region	   "calc" "Grab region of Calc data" t)
(autoload 'calc-grab-rectangle	   "calc" "Grab rectangle of data" t)

;; \e# is what the Calc manual binds it to.  Do not take a key the user may
;; have bound: only claim it if it is still free.
(if (keymapp (current-global-map))
    (if (null (global-key-binding "\e#"))
	(global-set-key "\e#" 'calc-dispatch)))
