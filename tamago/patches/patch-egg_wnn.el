$NetBSD$

Two functions that are gone in modern Emacs sit on the path that connects to
the conversion server, so this is the first thing a user reaches after the
input method is activated.

string-to-int became string-to-number, which has been there all along.

process-kill-without-query is asked for by fboundp rather than replaced,
because this package is still built for emacs20 and emacs21 and
set-process-query-on-exit-flag is not in all of them.

--- egg/wnn.el.orig
+++ egg/wnn.el
@@ -1227,7 +1227,7 @@
 		  myname (if (equal hostname "") "unix" wnn-system-name))
 	    (if (null (string-match ":" hostname))
 		(setq port-off 0)
-	      (setq port-off (string-to-int (substring hostname (match-end 0)))
+	      (setq port-off (string-to-number (substring hostname (match-end 0)))
 		    hostname (substring hostname 0 (match-beginning 0))))
 	    (and (equal hostname "") (setq hostname "localhost"))
 	    (let ((inhibit-quit save-inhibit-quit))
@@ -1244,7 +1244,9 @@
 						  (+ port port-off)))
 		((error quit))))
 	    (when proc
-	      (process-kill-without-query proc)
+	      (if (fboundp 'set-process-query-on-exit-flag)
+	          (set-process-query-on-exit-flag proc nil)
+	        (process-kill-without-query proc))
 	      (set-process-coding-system proc 'binary 'binary)
 	      (set-process-sentinel proc 'wnn-comm-sentinel)
 	      (set-marker-insertion-type (process-mark proc) t)
