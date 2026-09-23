$NetBSD$

Two functions that are gone in modern Emacs sit on the path that connects to
the conversion server, so this is the first thing a user reaches after the
input method is activated.

string-to-int became string-to-number, which has been there all along.

process-kill-without-query is asked for by fboundp rather than replaced,
because this package is still built for emacs20 and emacs21 and
set-process-query-on-exit-flag is not in all of them.

--- egg/sj3.el.orig
+++ egg/sj3.el
@@ -146,7 +146,9 @@
 	(setq proc (open-network-stream "SJ3" buf hostname sj3-server-port))
       ((error quit)
        (egg-error "failed to connect sj3 server")))
-    (process-kill-without-query proc)
+    (if (fboundp 'set-process-query-on-exit-flag)
+        (set-process-query-on-exit-flag proc nil)
+      (process-kill-without-query proc))
     (set-process-coding-system proc 'binary 'binary)
     (set-marker-insertion-type (process-mark proc) t)
     (save-excursion
