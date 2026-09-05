$NetBSD$

Adds the buffer-local variable untrusted-content, which the Org change in
patch-lisp_textmodes_org.el reads before deciding whether to run LaTeX on
content that came from the buffer, and which patch-lisp_gnus_mm-view.el sets
on a buffer holding a MIME part.  Nothing changes on its own; this is the
piece the other two stand on.

	ccc188fcf9  * lisp/files.el (untrusted-content): New variable.  (29.3)

defvar-local arrives in 24.3, so this is written as defvar plus
make-variable-buffer-local.  trusted-content-p, which the same upstream series
adds, is not here: its only user is elisp-mode.el, which this Emacs does not
have.  editors/emacs23 carries the same thing.

--- lisp/files.el.orig
+++ lisp/files.el
@@ -441,6 +441,15 @@
 (make-variable-buffer-local 'write-contents-functions)
 (define-obsolete-variable-alias 'write-contents-hooks
     'write-contents-functions "22.1")
+
+(defvar untrusted-content nil
+  "Non-nil means that current buffer originated from an untrusted source.
+Email clients and some other modes may set this non-nil to mark the
+buffer contents as untrusted.
+
+This variable might be subject to change without notice.")
+(make-variable-buffer-local 'untrusted-content)
+(put 'untrusted-content 'permanent-local t)
 
 (defcustom enable-local-variables t
   "Control use of local variables in files you visit.
