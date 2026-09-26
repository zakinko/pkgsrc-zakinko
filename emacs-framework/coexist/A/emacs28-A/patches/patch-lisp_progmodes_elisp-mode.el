$NetBSD$

Completion of local variables macroexpands the surrounding form, and
expanding a macro runs the macro's own code.  In a file that is only being
read, that is code the file chose.  This is CVE-2024-53920, upstream commit

	b5158bd191  elisp-mode.el: Disable Flymake byte-compile backend in
	            untrusted files

from Emacs 30.

Only the guard is taken.  Upstream's elisp--safe-macroexpand-all also uses
elisp--local-macroenv and macroexp-inhibit-compiler-macros and advises
macroexpand-1; 28.2 has none of the three, so the body here is 28.2's own
expansion, unchanged, wrapped in the trusted-content-p test.  The security
property is in the test, not in what is advised.

--- lisp/progmodes/elisp-mode.el.orig
+++ lisp/progmodes/elisp-mode.el
@@ -382,7 +382,33 @@
     res))
 
 (defvar warning-minimum-log-level)
+
+(defvar elisp--macroexpand-untrusted-warning t)
 
+(defun elisp--safe-macroexpand-all (sexp)
+  ;; Backported from Emacs 30 (CVE-2024-53920).  Upstream's body uses
+  ;; elisp--local-macroenv and macroexp-inhibit-compiler-macros, neither of
+  ;; which exists in 28.2, and advises macroexpand-1; the expansion below is
+  ;; therefore 28.2's own, unchanged.  What is taken from upstream is the
+  ;; guard: do not macroexpand at all when the buffer is not trusted, because
+  ;; expanding a macro runs the macro's own code.
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
+          (let ((warning-minimum-log-level :emergency))
+            (advice-add 'macroexpand :around macroexpand-advice)
+            (macroexpand-all sexp))
+        (advice-remove 'macroexpand macroexpand-advice)))))
+
 (defun elisp--local-variables ()
   "Return a list of locally let-bound variables at point."
   (save-excursion
@@ -398,17 +424,8 @@
                        (car (read-from-string
                              (concat txt "elisp--witness--lisp" closer)))
                      ((invalid-read-syntax end-of-file) nil)))
-             (macroexpand-advice (lambda (expander form &rest args)
-                                   (condition-case nil
-                                       (apply expander form args)
-                                     (error form))))
-             (sexp
-              (unwind-protect
-                  (let ((warning-minimum-log-level :emergency))
-                    (advice-add 'macroexpand :around macroexpand-advice)
-                    (macroexpand-all sexp))
-                (advice-remove 'macroexpand macroexpand-advice)))
-             (vars (elisp--local-variables-1 nil sexp)))
+             (vars (elisp--local-variables-1
+                    nil (elisp--safe-macroexpand-all sexp))))
         (delq nil
               (mapcar (lambda (var)
                         (and (symbolp var)
@@ -2054,6 +2071,14 @@
   "A Flymake backend for elisp byte compilation.
 Spawn an Emacs process that byte-compiles a file representing the
 current buffer state and calls REPORT-FN when done."
+  (unless (trusted-content-p)
+    ;; FIXME: Use `bwrap' and friends to compile untrusted content.
+    ;; FIXME: We emit a message *and* signal an error, because by default
+    ;; Flymake doesn't display the warning it puts into "*flmake log*".
+    (message "Disabling elisp-flymake-byte-compile in %s (untrusted content)"
+             (buffer-name))
+    (error "Disabling elisp-flymake-byte-compile in %s (untrusted content)"
+           (buffer-name)))
   (when elisp-flymake--byte-compile-process
     (when (process-live-p elisp-flymake--byte-compile-process)
       (kill-process elisp-flymake--byte-compile-process)))
