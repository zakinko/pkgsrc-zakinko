$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

Keep the added headers out of the Makefile-generating pass.

config.h is read twice: once by the compiler, and once by the cpp run that
turns Makefile.in into Makefile.  The second one is traditional cpp and
cannot read a modern glibc header at all, so the includes have to sit
inside #ifndef NOT_C_CODE, the way s/irix4-0.h does it.

--- src/frame.c.orig
+++ src/frame.c
@@ -1728,7 +1728,7 @@
 }
 
 
-choose_minibuf_frame ()
+int choose_minibuf_frame ()
 {
   /* For lowest-level minibuf, put it on currently selected frame
      if frame has a minibuffer.  */
@@ -1748,7 +1748,7 @@
     }
 }
 
-syms_of_frame ()
+void syms_of_frame ()
 {
  /*&&& init symbols here &&&*/
   Qframep = intern ("framep");
@@ -1855,7 +1855,7 @@
   defsubr (&Sset_frame_position);
 }
 
-keys_of_frame ()
+void keys_of_frame ()
 {
   initial_define_lispy_key (global_map, "switch-frame", "handle-switch-frame");
 }
@@ -2214,6 +2214,7 @@
   return Qt;
 }
 
+void
 syms_of_frame ()
 {
 #ifdef TERMINAL_FACE
@@ -2277,6 +2278,7 @@
   defsubr (&Sframe_live_p);
 }
 
+void
 keys_of_frame ()
 {
 }
