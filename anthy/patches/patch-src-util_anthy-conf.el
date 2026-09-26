$NetBSD$

cadr is not in Emacs 19.28, so Mule 2.3 cannot compile this file; it is
written out as car of cdr.

anthy.el sets anthy-rkmap-keybind, anthy-mode-map and anthy-mapc-function and
then requires this file, which cannot require it back.  Declaring them here,
and autoloading anthy-send-recv-command from anthy, is what takes this file
to no byte-compile warnings.  The mapcar whose value was thrown away goes
through anthy-mapc-function, which is mapc where there is one.

See patch-src-util_anthy.el for the rest of this.

--- src-util/anthy-conf.el.orig
+++ src-util/anthy-conf.el
@@ -1,4 +1,4 @@
-;; anthy-conf.el -- Anthy
+;; anthy-conf.el -- Anthy  -*- lexical-binding: nil -*-
 
 
 ;; Copyright (C) 2002
@@ -9,6 +9,13 @@
 ;;; Commentary:
 ;;
 
+;; Declared, not defined: anthy.el sets all three, then requires this file.
+;; anthy-conf.el cannot require anthy.el back, so without these the byte
+;; compiler reports free variables and an unknown function.
+(defvar anthy-rkmap-keybind)
+(defvar anthy-mode-map)
+(defvar anthy-mapc-function)
+(autoload 'anthy-send-recv-command "anthy")
 (defvar anthy-alt-char-map
   '(("," "，")
     ("." "．")))
@@ -79,9 +86,9 @@
 (defun anthy-change-katakana-map (key str)
   (anthy-send-map-edit-command 3 key str))
 (defun anthy-load-hiragana-map (map)
-  (mapcar (lambda (x)
+  (funcall anthy-mapc-function (lambda (x)
 	    (let ((key (car x))
-		  (str (cadr x)))
+		  (str (car (cdr x))))
 	      (anthy-change-hiragana-map key str))) map))
 (defun anthy-clear-map ()
   (anthy-send-recv-command
@@ -105,10 +112,10 @@
   (anthy-send-recv-command " SET_PREEDIT_MODE 1\n")
   (anthy-send-change-toggle-command "!")
   (anthy-clear-map)
-  (mapcar (lambda (x)
+  (funcall anthy-mapc-function (lambda (x)
 	    (anthy-change-hiragana-map (car x) (cdr x)))
 	  anthy-kana-mode-hiragana-map)
-  (mapcar (lambda (x)
+  (funcall anthy-mapc-function (lambda (x)
 	    (anthy-change-katakana-map (car x) (cdr x)))
 	  anthy-kana-mode-katakana-map))
 ;;
