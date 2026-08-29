$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/buffer.c.orig
+++ src/buffer.c
@@ -200,7 +200,7 @@
 /* 94.7.12 by K.Handa */
 Lisp_Object Vdefault_mc_flag;
 
-nsberror (spec)
+int nsberror (spec)
      Lisp_Object spec;
 {
   if (XTYPE (spec) == Lisp_String)
@@ -372,7 +372,7 @@
   reset_buffer_local_variables(b);
 }
 
-reset_buffer_local_variables (b)
+int reset_buffer_local_variables (b)
      register struct buffer *b;
 {
   register int offset;
@@ -895,7 +895,7 @@
    selected buffers are always closer to the front of the list.  This
    means that other_buffer is more likely to choose a relevant buffer.  */
 
-record_buffer (buf)
+int record_buffer (buf)
      Lisp_Object buf;
 {
   register Lisp_Object link, prev;
@@ -1142,7 +1142,7 @@
   return Qnil;
 }
 
-validate_region (b, e)
+int validate_region (b, e)
      register Lisp_Object *b, *e;
 {
   register Lisp_Object_Int i;
@@ -1173,7 +1173,7 @@
 }
 
 /* 91.11.14, 92.10.22 by K.Handa */
-validate_position (pos, forward)
+int validate_position (pos, forward)
      register int pos, forward;
 {
   if ((pos < ZV) && NONASCII_P (FETCH_CHAR (pos))) /* 92.10.30 by T.Enami */
@@ -2472,7 +2472,7 @@
 	 type_name, symbol_name);
 }
 
-init_buffer_once ()
+int init_buffer_once ()
 {
   register Lisp_Object tem;
 
@@ -2619,7 +2619,7 @@
   Fset_buffer (Fget_buffer_create (build_string ("*scratch*")));
 }
 
-init_buffer ()
+int init_buffer ()
 {
   char buf[MAXPATHLEN+1];
   char *pwd;
@@ -2653,7 +2653,7 @@
 }
 
 /* initialize the buffer routines */
-syms_of_buffer ()
+int syms_of_buffer ()
 {
   extern Lisp_Object Qdisabled;
 
@@ -3165,7 +3165,7 @@
   defsubr (&Sfix_overlay_end);
 }
 
-keys_of_buffer ()
+int keys_of_buffer ()
 {
   initial_define_key (control_x_map, 'b', "switch-to-buffer");
   initial_define_key (control_x_map, 'k', "kill-buffer");
