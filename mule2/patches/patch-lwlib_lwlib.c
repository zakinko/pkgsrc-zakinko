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

lwlib calls malloc, free and abort without declaring them.  With no
prototype the compiler assumes each returns int, and on LP64 the pointer
malloc returns is cut down to 32 bits before it is stored.  Include
<stdlib.h> so the real declarations are in scope.

--- lwlib/lwlib.c.orig
+++ lwlib/lwlib.c
@@ -43,6 +43,9 @@
 #endif
 #if defined (USE_XAW)
 #include "lwlib-Xaw.h"
+
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
 #endif
 
 #if __STDC__
@@ -1274,11 +1277,11 @@
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
