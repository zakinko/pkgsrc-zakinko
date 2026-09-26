$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/print.c.orig
+++ src/print.c
@@ -314,7 +314,7 @@
 /* Print the contents of a string STRING using PRINTCHARFUN.
    It isn't safe to use strout, because printing one char can relocate.  */
 
-print_string (string, printcharfun)
+int print_string (string, printcharfun)
      Lisp_Object string;
      Lisp_Object printcharfun;
 {
@@ -358,7 +358,7 @@
    on the default output stream.
    Do not use this on the contents of a Lisp string.  */
 
-write_string (data, size)
+int write_string (data, size)
      char *data;
      int size;
 {
@@ -379,7 +379,7 @@
    on a specified stream PRINTCHARFUN.
    Do not use this on the contents of a Lisp string.  */
 
-write_string_1 (data, size, printcharfun)
+int write_string_1 (data, size, printcharfun)
      char *data;
      int size;
      Lisp_Object printcharfun;
