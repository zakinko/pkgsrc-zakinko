$NetBSD$

Terminate execlp's argument list with (char *)NULL, not 0.

execl and friends read the terminator as a char *.  On an LP64 machine 0 is
an int, so only 32 bits get pushed and the callee keeps walking into
whatever was left on the stack.  This is the same mistake as the XtVa*
calls fixed elsewhere in this tree, in a place that has nothing to do with
X: sys_subshell() spawning the user's shell.

The cast is spelled (char *)0 rather than NULL because this file undefines
NULL at line 27 and never pulls in a header that puts it back.

--- src/sysdep.c.orig
+++ src/sysdep.c
@@ -725,7 +725,7 @@
       if (st)
         report_file_error ("Can't execute subshell", Fcons (build_string (sh), Qnil));
 #else /* not MSDOS */
-      execlp (sh, sh, 0);
+      execlp (sh, sh, (char *)0);
       write (1, "Can't execute subshell", 22);
       _exit (1);
 #endif /* not MSDOS */
