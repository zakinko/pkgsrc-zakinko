$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

Fix what only the Linux arm of this file compiles.

These lines are inside #ifdef arms that NetBSD does not take, so nothing
here shows up when the package is built there.  glibc reaches them.

--- src/ccl.c.orig
+++ src/ccl.c
@@ -31,6 +31,7 @@
 #include <stdio.h>
 #ifdef emacs
 #include <config.h>
+#include <string.h>
 #include "lisp.h"
 #include "charset.h"
 #include "coding.h"
@@ -152,7 +153,7 @@
   }\
 }
 
-ccl_driver(ccl, src, dst, n, end_flag)
+int ccl_driver(ccl, src, dst, n, end_flag)
      CCL_PROGRAM *ccl;
      unsigned char *src, *dst;
      int n, end_flag;
@@ -394,7 +395,7 @@
   return (d - dst);
 }
 
-set_ccl_program (ccl, val)
+int set_ccl_program (ccl, val)
      CCL_PROGRAM *ccl;
      Lisp_Object val;
 {
@@ -569,7 +570,7 @@
 		make_number ((int)(etime % 1000)));
 }
 
-syms_of_ccl ()
+int syms_of_ccl ()
 {
   staticpro (&Vx_ccl_programs);
   Vx_ccl_programs = Fmake_vector (128, Qnil);
