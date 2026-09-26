$NetBSD$

Loading un-define.el is very slow on Mule 5 (Emacs 21).  Each coding system is
defined once per eol-type, and register-char-codings -- which Mule 5 has and
Mule 4 does not -- is expensive for definitions of this shape.

Where register-char-codings exists, define each coding system once and let the
eol-type be decided the way Mule 5 decides it.  Elsewhere the original loop is
kept unchanged.

--- lisp/un-define.el.orig	2001-03-06 22:41:38.000000000 +0000
+++ lisp/un-define.el
@@ -610,13 +610,21 @@ by calling post-read-conversion and pre-
 
  (mapcar
   (lambda (x)
-    (mapcar
-     (lambda (y)
-       (mucs-define-coding-system
-	(nth 0 y) (nth 1 y) (nth 2 y)
-	(nth 3 y) (nth 4 y) (nth 5 y) (nth 6 y))
-       (coding-system-put (car y) 'alias-coding-systems (list (car x))))
-     (cdr x)))
+    (if (fboundp 'register-char-codings)
+	;; Mule 5, where we don't need the eol-type specified and
+	;; register-char-codings may be very slow for these coding
+	;; system definitions.
+	(let ((y (cadr x)))
+	  (mucs-define-coding-system
+	   (car x) (nth 1 y) (nth 2 y)
+	   (nth 3 y) (nth 4 y) (nth 5 y)))
+      (mapcar
+       (lambda (y)
+	 (mucs-define-coding-system
+	  (nth 0 y) (nth 1 y) (nth 2 y)
+	  (nth 3 y) (nth 4 y) (nth 5 y) (nth 6 y))
+	 (coding-system-put (car y) 'alias-coding-systems (list (car x))))
+      (cdr x))))
   `((utf-8
      (utf-8-unix
       ?u "UTF-8 coding system"
