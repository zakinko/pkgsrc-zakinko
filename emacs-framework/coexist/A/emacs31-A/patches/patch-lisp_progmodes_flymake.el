$NetBSD$

Copy trusted-content-p to flymake.el so flymake does not run backends
on untrusted content (Gentoo bug 982533).
From emacs commit 49c77fb219cbab8fc9d1b172fe754c2a2e4d9c53 (emacs-31 branch).

--- lisp/progmodes/flymake.el.orig
+++ lisp/progmodes/flymake.el
@@ -1271,8 +1271,13 @@
             (flymake--state-disabled state) nil
             (flymake--state-reported-p state) nil))
     (condition-case-unless-debug err
-        (apply backend (flymake-make-report-fn backend run-token)
-               args)
+        (if (or (trusted-content-p) (function-get backend 'flymake-always-safe))
+            (apply backend (flymake-make-report-fn backend run-token)
+                   args)
+          (message "Disabling %S in %s (untrusted content)"
+                   backend (buffer-name))
+          (user-error "Disabling %S in %s (untrusted content)"
+                      backend (buffer-name)))
       (error
        (flymake--disable-backend backend err)))))
 
