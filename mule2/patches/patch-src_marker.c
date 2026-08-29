$NetBSD: patch-src_marker.c,v 1.1 2013/04/21 15:40:00 joerg Exp $

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

--- src/marker.c.orig
+++ src/marker.c
@@ -221,8 +221,7 @@
    so we must be careful to ignore and preserve mark bits,
    including those in chain fields of markers.  */
 
-unchain_marker (marker)
-     register Lisp_Object marker;
+void unchain_marker (Lisp_Object marker)
 {
   register Lisp_Object tail, prev, next;
   register Lisp_Object_Int omark;
@@ -268,7 +267,7 @@
   XMARKER (marker)->buffer = 0;
 }
 
-marker_position (marker)
+int marker_position (marker)
      Lisp_Object marker;
 {
   register struct Lisp_Marker *m = XMARKER (marker);
@@ -319,7 +318,7 @@
     }
 }
 
-syms_of_marker ()
+int syms_of_marker ()
 {
   defsubr (&Smarker_position);
   defsubr (&Smarker_buffer);
