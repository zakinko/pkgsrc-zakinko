$NetBSD$

Keep the added headers out of the Makefile-generating pass.

config.h is read twice: once by the compiler, and once by the cpp run that
turns Makefile.in into Makefile.  The second one is traditional cpp and
cannot read a modern glibc header at all, so the includes have to sit
inside #ifndef NOT_C_CODE, the way s/irix4-0.h does it.

--- src/systime.h.orig
+++ src/systime.h
@@ -19,6 +19,7 @@
 
 #ifdef TIME_WITH_SYS_TIME
 #include <sys/time.h>
+#include <utime.h>	/* utime の宣言。glibc は自分から出さない */
 #include <time.h>
 #else
 #ifdef HAVE_SYS_TIME_H
@@ -152,10 +153,10 @@
 
 #define EMACS_SET_UTIMES(path, atime, mtime)			\
   {								\
-    time_t tv[2];						\
-    tv[0] = EMACS_SECS (atime);					\
-    tv[1] = EMACS_SECS (mtime);					\
-    utime ((path), tv);						\
+    struct utimbuf tv;						\
+    tv.actime = EMACS_SECS (atime);				\
+    tv.modtime = EMACS_SECS (mtime);				\
+    utime ((path), &tv);					\
   }
 
 #else /* ! defined (USE_UTIME) */
