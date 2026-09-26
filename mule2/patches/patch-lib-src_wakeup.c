$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

--- lib-src/wakeup.c.orig
+++ lib-src/wakeup.c
@@ -5,6 +5,13 @@
 #include <stdio.h>
 #include <sys/types.h>
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+#include <unistd.h>
+
+/* Declare the standard functions this file calls. */
+#include <time.h>
+
 #ifdef TIME_WITH_SYS_TIME
 #include <sys/time.h>
 #include <time.h>
@@ -18,7 +25,7 @@
 
 struct tm *localtime ();
 
-main (argc, argv)
+int main (argc, argv)
      int argc;
      char **argv;
 {
