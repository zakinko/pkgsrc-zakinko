$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

--- src/prefix-args.c.orig
+++ src/prefix-args.c
@@ -26,6 +26,9 @@
 
 #include <stdio.h>
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+
 main (argc, argv)
      int argc;
      char **argv;
