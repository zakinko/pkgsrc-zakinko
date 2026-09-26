$NetBSD$

When FIONREAD on the input fd fails, Emacs 20 sends itself SIGHUP, on
the theory that the terminal is gone.  In batch mode there is no
terminal: with stdin redirected from /dev/null, which NetBSD answers
with ENOTSUP, the first sleep-for or accept-process-output after a
subprocess is started kills Emacs (exit 129).  Treat the failure as
"no input" when noninteractive, as later Emacsen do.

--- src/keyboard.c.orig	2000-06-08 05:01:19.000000000 +0000
+++ src/keyboard.c
@@ -5383,7 +5383,12 @@
 	/* ??? Is it really right to send the signal just to this process
 	   rather than to the whole process group?
 	   Perhaps on systems with FIONREAD Emacs is alone in its group.  */
-	kill (getpid (), SIGHUP);
+	{
+	  if (noninteractive)
+	    n_to_read = 0;
+	  else
+	    kill (getpid (), SIGHUP);
+	}
       if (n_to_read == 0)
 	return 0;
       if (n_to_read > sizeof cbuf)
