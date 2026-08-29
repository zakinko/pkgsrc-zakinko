$NetBSD$

The "nothing" member is there to give the union a size when neither X nor w32
is compiled in.  int is too small on LP64, so the union came out shorter than
a pointer and the frame structure did not line up.

--- ./src/frame.h.orig	Sat Apr 25 16:17:34 1998
+++ ./src/frame.h	Tue Sep 26 09:38:18 2000
@@ -186,7 +186,7 @@
      it is defined in xterm.h.  
      struct w32_output is used for W32 window frames;
      it is defined in w32term.h.  */
-  union output_data { struct x_output *x; struct w32_output *w32; int nothing; } output_data;
+  union output_data { struct x_output *x; struct w32_output *w32; EMACS_INT nothing; } output_data;
 
 #ifdef MULTI_KBOARD
   /* A pointer to the kboard structure associated with this frame.
