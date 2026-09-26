$NetBSD$

execlp takes a variable number of arguments and reads the terminator as a
char *.  A bare 0 is an int, so on LP64 only 32 bits go on the stack and the
callee reads whatever is left in the other half as part of the pointer.  It
is not the terminator any more.  Cast it.

This is the same family as the XtVa* calls in the 2.3 tree, where 44 call
sites end in a bare 0 and one crashes libXt on NetBSD 9.4.  1.1 has exactly
one, here, in sys_subshell().

--- src/sysdep.c.orig
+++ src/sysdep.c
@@ -994,7 +994,7 @@
       system (sh);
       chdir (oldwd);
 #else /* not MSDOS */
-      execlp (sh, sh, 0);
+      execlp (sh, sh, (char *) 0);
       write (1, "Can't execute subshell", 22);
       _exit (1);
 #endif /* not MSDOS */
