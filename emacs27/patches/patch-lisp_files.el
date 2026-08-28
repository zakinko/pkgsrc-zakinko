$NetBSD$

Adds the buffer-local variable untrusted-content, which the Gnus and Org
changes here read before deciding whether to run code that came from the
buffer.  Nothing changes on its own; this is the piece the others stand on.

	ccc188fcf9  * lisp/files.el (untrusted-content): New variable.  (29.3)

--- lisp/files.el.orig
+++ lisp/files.el
@@ -587,7 +587,15 @@
   "Non-nil means enable use of directory-local variables.
 Some modes may wish to set this to nil to prevent directory-local
 settings being applied, but still respect file-local ones.")
+
+(defvar-local untrusted-content nil
+  "Non-nil means that current buffer originated from an untrusted source.
+Email clients and some other modes may set this non-nil to mark the
+buffer contents as untrusted.
 
+This variable might be subject to change without notice.")
+(put 'untrusted-content 'permanent-local t)
+
 ;; This is an odd variable IMO.
 ;; You might wonder why it is needed, when we could just do:
 ;; (set (make-local-variable 'enable-local-variables) nil)
