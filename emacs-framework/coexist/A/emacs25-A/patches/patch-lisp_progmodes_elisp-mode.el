$NetBSD$

Completion of local variables macroexpands the surrounding form, and
expanding a macro runs the macro's own code.  In a file that is only being
read, that is code the file chose.  This is CVE-2024-53920, upstream commit

	b5158bd191  elisp-mode.el: Disable Flymake byte-compile backend in
	            untrusted files

from Emacs 30.

Only the guard is taken.  Upstream's elisp--safe-macroexpand-all also uses
elisp--local-macroenv and macroexp-inhibit-compiler-macros and advises
macroexpand-1; this version has none of the three, so the body here is its
own expansion, unchanged, wrapped in the trusted-content-p test.  The
security property is in the test, not in what is advised.

The flymake byte-compile half of the upstream commit is not here: 25.3 has no
elisp-flymake-byte-compile at all.

--- lisp/progmodes/elisp-mode.el.orig
+++ lisp/progmodes/elisp-mode.el
@@ -304,7 +304,33 @@
           ;; backtrack to the last-but-one.
           (setq sexp (ignore-errors (butlast sexp)))))
     res))
+
+(defvar elisp--macroexpand-untrusted-warning t)
 
+(defun elisp--safe-macroexpand-all (sexp)
+  ;; Backported from Emacs 30 (CVE-2024-53920).  Upstream's body uses
+  ;; elisp--local-macroenv and macroexp-inhibit-compiler-macros, neither of
+  ;; which exists here, and advises macroexpand-1; the expansion below is
+  ;; therefore this version's own, unchanged.  What is taken from upstream is
+  ;; the guard: do not macroexpand at all when the buffer is not trusted,
+  ;; because expanding a macro runs the macro's own code.
+  (if (not (trusted-content-p))
+      (progn
+        (when elisp--macroexpand-untrusted-warning
+          (setq-local elisp--macroexpand-untrusted-warning nil) ;Don't spam!
+          (message "Completion of local vars is disabled in %s (untrusted content)"
+                   (buffer-name)))
+        sexp)
+    (let ((macroexpand-advice (lambda (expander form &rest args)
+                                (condition-case nil
+                                    (apply expander form args)
+                                  (error form)))))
+      (unwind-protect
+          (progn
+            (advice-add 'macroexpand :around macroexpand-advice)
+            (macroexpand-all sexp))
+        (advice-remove 'macroexpand macroexpand-advice)))))
+
 (defun elisp--local-variables ()
   "Return a list of locally let-bound variables at point."
   (save-excursion
@@ -320,17 +346,8 @@
                        (car (read-from-string
                              (concat txt "elisp--witness--lisp" closer)))
                      ((invalid-read-syntax end-of-file) nil)))
-             (macroexpand-advice (lambda (expander form &rest args)
-                                   (condition-case nil
-                                       (apply expander form args)
-                                     (error form))))
-             (sexp
-              (unwind-protect
-                  (progn
-                    (advice-add 'macroexpand :around macroexpand-advice)
-                    (macroexpand-all sexp))
-                (advice-remove 'macroexpand macroexpand-advice)))
-             (vars (elisp--local-variables-1 nil sexp)))
+             (vars (elisp--local-variables-1
+                    nil (elisp--safe-macroexpand-all sexp))))
         (delq nil
               (mapcar (lambda (var)
                         (and (symbolp var)
