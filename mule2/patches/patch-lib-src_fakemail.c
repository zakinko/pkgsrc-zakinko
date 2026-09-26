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

Fix what only the Linux arm of this file compiles.

These lines are inside #ifdef arms that NetBSD does not take, so nothing
here shows up when the package is built there.  glibc reaches them.

Fix what only the Linux arm of this file compiles.

These lines are inside #ifdef arms that NetBSD does not take, so nothing
here shows up when the package is built there.  glibc reaches them.

--- lib-src/fakemail.c.orig
+++ lib-src/fakemail.c
@@ -21,9 +21,16 @@
 #define NO_SHORTNAMES
 #include <../src/config.h>
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+
+/* Declare the standard functions this file calls. */
+#include <string.h>
+#include <time.h>
+
 #if defined (BSD) && !defined (BSD4_1) && !defined (USE_FAKEMAIL)
 /* This program isnot used in BSD, so just avoid loader complaints.  */
-main ()
+int main ()
 {
 }
 #else /* not BSD 4.2 (or newer) */
@@ -127,8 +134,10 @@
 static boolean no_problems = true;
 
 extern FILE *popen ();
+/* cuserid は POSIX から外れ、FreeBSD の libc に無い。この file には
+   getpwuid を使う CURRENT_USER の枝があるので、そちらを選ぶ。 */
+#define CURRENT_USER
 extern int fclose (), pclose ();
-extern char *malloc (), *realloc ();
 
 #ifdef CURRENT_USER
 extern struct passwd *getpwuid ();
@@ -521,6 +530,7 @@
   return size;
 }
 
+void
 parse_header (the_header, where)
      header the_header;
      register char *where;
