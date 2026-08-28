$NetBSD$

xrdb.c redefines malloc and realloc to Emacs own allocators but does not
declare them: the file says "Make sure not to #include anything after these
definitions" and lisp.h is not among its includes.  alloc.c defines them as
returning long *, so on LP64 the implicit declaration makes the caller read
back only the low 32 bits of every pointer the X resource database allocates.
It dies as soon as one of those allocations lands above 4GB, during X
initialization, before any Lisp is read.

The tree already knew: the OSF1 arm right below declares the two after the
#define (so it declares xmalloc and xrealloc), which spared Alpha, the first
LP64 Unix this ran on.  Do it for everyone.

--- src/xrdb.c.orig
+++ src/xrdb.c
@@ -89,6 +89,14 @@
 #define malloc xmalloc
 #define realloc xrealloc
 #define free xfree
+/* Declare them.  They return long *, and on LP64 an implicit declaration
+   makes the caller read back only the low 32 bits of the pointer.  The
+   OSF1 arm below did this for Alpha, the first LP64 Unix this ran on;
+   everyone else got the truncation.  Note the names are already rewritten
+   by the #define above, so this declares xmalloc and xrealloc.  */
+extern long *malloc ();
+extern long *realloc ();
+extern void free ();
 #endif
 
 #ifdef OSF1
