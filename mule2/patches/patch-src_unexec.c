$NetBSD$

Keep the added headers out of the Makefile-generating pass.

config.h is read twice: once by the compiler, and once by the cpp run that
turns Makefile.in into Makefile.  The second one is traditional cpp and
cannot read a modern glibc header at all, so the includes have to sit
inside #ifndef NOT_C_CODE, the way s/irix4-0.h does it.

--- src/unexec.c.orig
+++ src/unexec.c
@@ -327,7 +327,7 @@
 
 #include "lisp.h"
 
-static
+static int
 report_error (file, fd)
      char *file;
      int fd;
@@ -342,7 +342,9 @@
 #define ERROR1(msg,x) report_error_1 (new, msg, x, 0); return -1
 #define ERROR2(msg,x,y) report_error_1 (new, msg, x, y); return -1
 
-static
+static int write_segment ();
+
+static void
 report_error_1 (fd, msg, a1, a2)
      int fd;
      char *msg;
@@ -367,6 +369,7 @@
  *
  * driving logic.
  */
+int
 unexec (new_name, a_name, data_start, bss_start, entry_address)
      char *new_name, *a_name;
      unsigned data_start, bss_start, entry_address;
@@ -927,6 +930,7 @@
   return 0;
 }
 
+static int
 write_segment (new, ptr, end)
      int new;
      register char *ptr, *end;
