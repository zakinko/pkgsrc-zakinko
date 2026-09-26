$NetBSD$

Same as patch-src-util_anthy-conf.el: declare what anthy.el defines before
this file is loaded, autoload the one function called from it, and put the
mapcar whose value is thrown away through anthy-mapc-function.

See patch-src-util_anthy.el for the rest of this.

--- src-util/anthy-azik.el.orig
+++ src-util/anthy-azik.el
@@ -1,4 +1,4 @@
-;; anthy-azik.el
+;; anthy-azik.el  -*- lexical-binding: nil -*-
 
 ;; Copyright (C) 2004
 ;; Author: Yutaka Hara<yhara@kmc.gr.jp>
@@ -8,6 +8,12 @@
 ;; (anthy-azik-mode)
 ;;
 
+;; Declared, not defined: anthy.el sets these, then this file is loaded on
+;; top of it.  Without the declarations the byte compiler reports a free
+;; variable and an unknown function.
+(defvar anthy-rkmap-keybind)
+(defvar anthy-mapc-function)
+(autoload 'anthy-hiragana-map "anthy")
 (defvar anthy-azik-mode-hiragana-map
   '(
     (";" . "っ")  ("x;" . ";")  ("b." . "ぶ")  ("bd" . "べん")  ("bh" . "ぶう")  
@@ -223,7 +229,7 @@
 	  (("katakana" . 16) . "hiragana")))
 ; (define-key anthy-mode-map (char-to-string 16) 'anthy-insert)
   (anthy-send-change-toggle-command "!")
-  (mapcar (lambda (x)
+  (funcall anthy-mapc-function (lambda (x)
 	    (anthy-change-hiragana-map (car x) (cdr x)))
 	  anthy-azik-mode-hiragana-map)
   (anthy-hiragana-map))
