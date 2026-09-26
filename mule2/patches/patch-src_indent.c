$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/indent.c.orig
+++ src/indent.c
@@ -122,7 +122,7 @@
 
 /* Cancel any recorded value of the horizontal position.  */
 
-invalidate_current_column ()
+int invalidate_current_column ()
 {
   last_known_column_point = 0;
 }
@@ -320,7 +320,7 @@
   return val;
 }
 
-position_indentation (pos)
+int position_indentation (pos)
      register int pos;
 {
   register int column = 0;
@@ -1497,7 +1497,7 @@
   return make_number (pos.vpos);
 }
 
-syms_of_indent ()
+int syms_of_indent ()
 {
   DEFVAR_BOOL ("indent-tabs-mode", &indent_tabs_mode,
     "*Indentation can insert tabs if this is non-nil.\n\
