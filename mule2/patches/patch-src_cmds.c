$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/cmds.c.orig
+++ src/cmds.c
@@ -403,7 +403,7 @@
    return 0.  A value of 1 indicates this *might* not have been simple.
    A value of 2 means this did things that call for an undo boundary.  */
 
-internal_self_insert (c1, noautofill)
+int internal_self_insert (c1, noautofill)
      int c1;			/* 92.1.16 by K.Handa */
      int noautofill;
 {				/* 92.1.16 by K.Handa */
@@ -509,7 +509,7 @@
 
 /* module initialization */
 
-syms_of_cmds ()
+int syms_of_cmds ()
 {
   Qkill_backward_chars = intern ("kill-backward-chars");
   staticpro (&Qkill_backward_chars);
@@ -543,7 +543,7 @@
   defsubr (&Snewline);
 }
 
-keys_of_cmds ()
+int keys_of_cmds ()
 {
   int n;
 
