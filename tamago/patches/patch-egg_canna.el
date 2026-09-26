$NetBSD$

Two functions that are gone in modern Emacs sit on the path that connects to
the conversion server, so this is the first thing a user reaches after the
input method is activated.

string-to-int became string-to-number, which has been there all along.

process-kill-without-query is asked for by fboundp rather than replaced,
because this package is still built for emacs20 and emacs21 and
set-process-query-on-exit-flag is not in all of them.

--- egg/canna.el.orig
+++ egg/canna.el
@@ -331,7 +331,7 @@
 	      (setq port (substring hostname (match-end 0))
 		    hostname (substring hostname 0 (match-beginning 0))))
 	    (if (and (stringp port) (string-match "^[0-9]+$" port))
-		(setq port (string-to-int port)))
+		(setq port (string-to-number port)))
 	    (and (equal hostname "")
 		 (setq hostname (or (getenv "CANNAHOST") "localhost")))
 	    (let ((inhibit-quit save-inhibit-quit))
@@ -346,7 +346,9 @@
 		  (setq proc (open-network-stream proc-name buf hostname port))
 		((error quit))))
 	    (when proc
-	      (process-kill-without-query proc)
+	      (if (fboundp 'set-process-query-on-exit-flag)
+	          (set-process-query-on-exit-flag proc nil)
+	        (process-kill-without-query proc))
 	      (set-process-coding-system proc 'binary 'binary)
 	      (set-process-sentinel proc 'canna-comm-sentinel)
 	      (set-marker-insertion-type (process-mark proc) t)
