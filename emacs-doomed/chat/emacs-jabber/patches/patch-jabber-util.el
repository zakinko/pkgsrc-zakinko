$NetBSD$

Emacs 20 has neither replace-regexp-in-string nor replace-in-string,
so the cond that defines jabber-replace-in-string ends in

	error (("No implementation of `jabber-replace-in-string' available"))

at byte-compile time.  devel/elisp-compat supplies the Emacs 21
function; the require is soft, so this is a no-op anywhere else.

--- jabber-util.el.orig
+++ jabber-util.el
@@ -33,6 +33,11 @@
   "History of entered JIDs")
 
 ;; Define `jabber-replace-in-string' somehow.
+;; Emacs 20 has neither replace-regexp-in-string nor replace-in-string,
+;; so the cond below ends in the error.  devel/elisp-compat supplies the
+;; former; the require is soft, so nothing changes where it is absent.
+(eval-and-compile
+  (require 'elisp-compat nil t))
 (cond
  ;; Emacs 21 has replace-regexp-in-string.
  ((fboundp 'replace-regexp-in-string)
