$NetBSD$

Two unrelated things in the same file, because pkgsrc takes one patch per
file.

CVE-2012-3479:
When the Emacs user option `enable-local-variables' is set to `:safe'
(the default value is t), Emacs should automatically refuse to evaluate
`eval' forms in file-local variable sections.  Due to the bug, Emacs
instead automatically evaluates such `eval' forms.  Thus, if the user
changes the value of `enable-local-variables' to `:safe', visiting a
malicious file can cause automatic execution of arbitrary Emacs Lisp
code with the permissions of the user.

Bug tracker ref: http://debbugs.gnu.org/cgi/bugreport.cgi?bug=12155

The other is the buffer-local variable untrusted-content, which the Org
change here reads before deciding whether to run LaTeX on content that came
from the buffer.  Nothing changes on its own; this is the piece that one
stands on.

	ccc188fcf9  * lisp/files.el (untrusted-content): New variable.  (29.3)

defvar-local arrived in 24.3, so it is made buffer-local with
make-variable-buffer-local, which is what defvar-local expands to.
trusted-content-p, which the same upstream series adds, is not here: its only
user is elisp-mode.el, which this Emacs does not have.

--- lisp/files.el.orig
+++ lisp/files.el
@@ -487,6 +487,15 @@
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
@@ -2986,11 +2995,16 @@
 	      ;; Obey `enable-local-eval'.
 	      ((eq var 'eval)
 	       (when enable-local-eval
-		 (push elt all-vars)
-		 (or (eq enable-local-eval t)
-		     (hack-one-local-variable-eval-safep (eval (quote val)))
-		     (safe-local-variable-p var val)
-		     (push elt unsafe-vars))))
+		 (let ((safe (or (hack-one-local-variable-eval-safep
+				  (eval (quote val)))
+				 ;; In case previously marked safe (bug#5636).
+				 (safe-local-variable-p var val))))
+		   ;; If not safe and e-l-v = :safe, ignore totally.
+		   (when (or safe (not (eq enable-local-variables :safe)))
+		     (push elt all-vars)
+		     (or (eq enable-local-eval t)
+			 safe
+			 (push elt unsafe-vars))))))
 	      ;; Ignore duplicates (except `mode') in the present list.
 	      ((and (assq var all-vars) (not (eq var 'mode))) nil)
 	      ;; Accept known-safe variables.
