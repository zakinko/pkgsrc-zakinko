$NetBSD: patch-bj,v 1.1.1.1 2003/04/11 00:31:45 uebayasi Exp $

Make Lisp_Object 64 bits wide on LP64, and declare four Lisp functions
that return one.

Nothing declares them, so the implicit int return truncates the value to
32 bits and the type tag (bits 60-62) goes with it.  Two of the four are
reached in practice:

	keyboard.c:2360   Vinput_method_previous_message = echo_area_message
			  = Fcurrent_message ();
	window.c:1968     XBUFFER (buffer)->display_time = Fcurrent_time ();

The first is on the input method path, taken whenever
input-method-function is set, which is what Japanese input runs into.
Fset_buffer_multibyte and Fwindow_end survive today, one because its
caller discards the result and the other because XINT masks the tag off
again, but they are the same mistake.

Emacs 21 declares all four; these are its lines, in its places.

--- ./src/lisp.h.orig	Sun Jan  3 08:31:23 1999
+++ ./src/lisp.h	Tue Sep 26 09:48:10 2000
@@ -123,25 +123,25 @@
   {
     /* Used for comparing two Lisp_Objects;
        also, positive integers can be accessed fast this way.  */
-    int i;
+    long int i;
 
     struct
       {
-	int val: VALBITS;
-	int type: GCTYPEBITS+1;
+	long int val: VALBITS;
+	long int type: GCTYPEBITS+1;
       } s;
     struct
       {
-	unsigned int val: VALBITS;
-	int type: GCTYPEBITS+1;
+	long unsigned int val: VALBITS;
+	long int type: GCTYPEBITS+1;
       } u;
     struct
       {
-	unsigned int val: VALBITS;
+	long unsigned int val: VALBITS;
 	enum Lisp_Type type: GCTYPEBITS;
 	/* The markbit is not really part of the value of a Lisp_Object,
 	   and is always zero except during garbage collection.  */
-	unsigned int markbit: 1;
+	long unsigned int markbit: 1;
       } gu;
   }
 Lisp_Object;
@@ -153,17 +153,17 @@
   {
     /* Used for comparing two Lisp_Objects;
        also, positive integers can be accessed fast this way.  */
-    int i;
+    long int i;
 
     struct
       {
-	int type: GCTYPEBITS+1;
-	int val: VALBITS;
+	long int type: GCTYPEBITS+1;
+	long int val: VALBITS;
       } s;
     struct
       {
-	int type: GCTYPEBITS+1;
-	unsigned int val: VALBITS;
+	long int type: GCTYPEBITS+1;
+	long unsigned int val: VALBITS;
       } u;
     struct
       {
@@ -171,7 +171,7 @@
 	   and is always zero except during garbage collection.  */
 	unsigned int markbit: 1;
 	enum Lisp_Type type: GCTYPEBITS;
-	unsigned int val: VALBITS;
+	long unsigned int val: VALBITS;
       } gu;
   }
 Lisp_Object;
@@ -270,14 +270,14 @@
 /* Extract the value of a Lisp_Object as a signed integer.  */
 
 #ifndef XINT   /* Some machines need to do this differently.  */
-#define XINT(a) (((a) << (BITS_PER_INT-VALBITS)) >> (BITS_PER_INT-VALBITS))
+#define XINT(a) (EMACS_INT) (((a) << (BITS_PER_EMACS_INT-VALBITS)) >> (BITS_PER_EMACS_INT-VALBITS))
 #endif
 
 /* Extract the value as an unsigned integer.  This is a basis
    for extracting it as a pointer to a structure in storage.  */
 
 #ifndef XUINT
-#define XUINT(a) ((a) & VALMASK)
+#define XUINT(a) (EMACS_UINT) ((a) & VALMASK)
 #endif
 
 #ifndef XPNTR
@@ -358,7 +358,7 @@
 
 #ifdef EXPLICIT_SIGN_EXTEND
 /* Make sure we sign-extend; compilers have been known to fail to do so.  */
-#define XINT(a) (((a).i << (BITS_PER_INT-VALBITS)) >> (BITS_PER_INT-VALBITS))
+#define XINT(a) (((a).i << (BITS_PER_EMACS_INT-VALBITS)) >> (BITS_PER_EMACS_INT-VALBITS))
 #else
 #define XINT(a) ((a).s.val)
 #endif /* EXPLICIT_SIGN_EXTEND */
@@ -367,7 +367,7 @@
 #define XPNTR(a) ((a).u.val)
 
 #define XSET(var, vartype, ptr) \
-   (((var).s.type = ((char) (vartype))), ((var).s.val = ((int) (ptr))))
+   (((var).s.type = ((char) (vartype))), ((var).s.val = ((EMACS_INT) (ptr))))
 
 extern Lisp_Object make_number ();
 
@@ -1997,6 +1997,7 @@
 extern void syms_of_eval P_ ((void));
 
 /* Defined in editfns.c */
+EXFUN (Fcurrent_message, 0);
 EXFUN (Fgoto_char, 1);
 EXFUN (Fpoint_min_marker, 0);
 EXFUN (Fpoint_max_marker, 0);
@@ -2035,6 +2036,7 @@
 EXFUN (Fwiden, 0);
 EXFUN (Fuser_login_name, 1);
 EXFUN (Fsystem_name, 0);
+EXFUN (Fcurrent_time, 0);
 extern int clip_to_bounds P_ ((int, int, int));
 extern Lisp_Object make_buffer_string P_ ((int, int, int));
 extern Lisp_Object make_buffer_string_both P_ ((int, int, int, int, int));
@@ -2043,6 +2045,7 @@
 
 /* defined in buffer.c */
 extern void nsberror P_ ((Lisp_Object));
+EXFUN (Fset_buffer_multibyte, 1);
 EXFUN (Foverlay_start, 1);
 EXFUN (Foverlay_end, 1);
 extern void adjust_overlays_for_insert P_ ((int, int));
@@ -2256,6 +2259,7 @@
 
 /* defined in window.c */
 extern Lisp_Object Qwindowp, Qwindow_live_p;
+EXFUN (Fwindow_end, 2);
 EXFUN (Fselected_window, 0);
 EXFUN (Fnext_window, 3);
 EXFUN (Fdelete_window, 1);
