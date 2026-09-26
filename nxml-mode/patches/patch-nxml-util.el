$NetBSD$

Emacs 20 has no inhibit-modification-hooks, so text property changes
made under this macro ran nxml-after-change again from inside itself.
Bind the change hooks to nil there instead.

--- nxml-util.el.orig
+++ nxml-util.el
@@ -51,6 +51,11 @@
     `(let ((,modified (buffer-modified-p))
 	   (inhibit-read-only t)
 	   (inhibit-modification-hooks t)
+	   ;; Emacs 20 has no inhibit-modification-hooks; silence the hooks
+	   ;; themselves there, or the property changes recurse into
+	   ;; nxml-after-change.
+	   (after-change-functions (if (boundp (quote inhibit-modification-hooks)) after-change-functions nil))
+	   (before-change-functions (if (boundp (quote inhibit-modification-hooks)) before-change-functions nil))
 	   (buffer-undo-list t)
 	   (deactivate-mark nil)
 	   ;; Apparently these avoid file locking problems.
