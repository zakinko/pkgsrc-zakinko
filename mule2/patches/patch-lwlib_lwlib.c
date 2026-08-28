$NetBSD$

Terminate the variadic argument lists with NULL, not 0.

XtVaSetValues and its relatives read the terminator as a pointer.  On an
LP64 machine 0 is an int, so only 32 bits get pushed and the upper half is
whatever the stack happened to hold; _XtCountVaList walks past the end of
the list and the process dies in libXt before any Lisp is read.  It has
been getting away with this on the machines where that leftover half
happened to be zero, which is why the same binary starts and stops working
as the Xt library changes underneath it.

NetBSD 9.4/amd64 was where it finally showed: mule -q died with SIGSEGV in
_XtCountVaList, while 10.1 and 11.0 with the same ABI were fine.

--- lwlib/lwlib.c.orig
+++ lwlib/lwlib.c
@@ -1274,11 +1274,11 @@
   XtVaGetValues (widget_to_invert,
 		 XtNforeground, &foreground,
 		 XtNbackground, &background,
-		 0);
+		 NULL);
   XtVaSetValues (widget_to_invert,
 		 XtNforeground, background,
 		 XtNbackground, foreground,
-		 0);
+		 NULL);
 }
 
 void
