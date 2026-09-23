$NetBSD$

Two functions that are gone in modern Emacs sit on the path that connects to
the conversion server, so this is the first thing a user reaches after the
input method is activated.

string-to-int became string-to-number, which has been there all along.

process-kill-without-query is asked for by fboundp rather than replaced,
because this package is still built for emacs20 and emacs21 and
set-process-query-on-exit-flag is not in all of them.

--- egg/anthy.el.orig
+++ egg/anthy.el
@@ -111,7 +111,9 @@
 	    (process-connection-type nil)) ; avoid using pty
 	(setq anthy-proc
 	      (start-process "anthy-agent" buf "anthy-agent" "--egg"))
-	(process-kill-without-query anthy-proc)
+	(if (fboundp 'set-process-query-on-exit-flag)
+	    (set-process-query-on-exit-flag anthy-proc nil)
+	  (process-kill-without-query anthy-proc))
 	(set-process-coding-system anthy-proc 'euc-jp-dos 'euc-jp-dos)
 	(set-process-sentinel anthy-proc 'anthy-proc-sentinel)
 	(set-marker-insertion-type (process-mark anthy-proc) t)
