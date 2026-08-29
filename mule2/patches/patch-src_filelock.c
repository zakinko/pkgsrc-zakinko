$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

--- src/filelock.c.orig
+++ src/filelock.c
@@ -38,6 +38,9 @@
 #include <paths.h>
 #include "buffer.h"
 
+/* Declare the standard functions this file calls. */
+#include <signal.h>
+
 #ifndef MCPATH
 #ifdef SYSV_SYSTEM_DIR
 #include <dirent.h>
