$NetBSD: patch-src_data.c,v 1.1 2013/04/21 15:39:59 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/data.c.orig
+++ src/data.c
@@ -111,7 +111,7 @@
   return value;
 }
 
-pure_write_error ()
+int pure_write_error ()
 {
   error ("Attempt to modify read-only object");
 }
@@ -2369,7 +2369,7 @@
   Fsignal (Qarith_error, Qnil);
 }
 
-init_data ()
+void init_data (void)
 {
   /* Don't do this if just dumping out.
      We don't want to call `signal' in this case
