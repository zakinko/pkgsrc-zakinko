$NetBSD$

tparam.c defines its own xmalloc and xrealloc, but inside #ifndef emacs.  Built
as part of emacs, which is how it is built here (-Demacs), nothing declares
them at all, so the compiler assumes they return int and the pointer is
truncated on LP64.  lisp.h:2484 has the declarations:

	extern long *xmalloc (), *xrealloc ();

--- src/tparam.c.orig	2004-03-25 22:23:54.000000000 +0100
+++ src/tparam.c	2004-03-25 22:26:40.000000000 +0100
@@ -36,6 +36,8 @@
 
 #endif /* not emacs */
 
+#include "lisp.h"
+
 #ifndef NULL
 #define NULL (char *) 0
 #endif
