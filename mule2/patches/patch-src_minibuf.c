$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/minibuf.c.orig
+++ src/minibuf.c
@@ -782,7 +782,7 @@
    Return -1 if strings match,
    else number of chars that match at the beginning.  */
 
-scmp (s1, s2, len)
+int scmp (s1, s2, len)
      register unsigned char *s1, *s2; /* 92.9.20 by T.Enami */
      int len;
 {
@@ -1029,7 +1029,7 @@
    that has no possible completions, and other quick, unobtrusive
    messages.  */
 
-temp_echo_area_glyphs (m)
+int temp_echo_area_glyphs (m)
      char *m;
 {
   int osize = ZV;
@@ -1612,13 +1612,13 @@
 }
 #endif
 
-init_minibuf_once ()
+int init_minibuf_once ()
 {
   Vminibuffer_list = Qnil;
   staticpro (&Vminibuffer_list);
 }
 
-syms_of_minibuf ()
+int syms_of_minibuf ()
 {
   minibuf_level = 0;
   minibuf_prompt = Qnil;
@@ -1760,7 +1760,7 @@
 #endif
 }
 
-keys_of_minibuf ()
+int keys_of_minibuf ()
 {
   initial_define_key (Vminibuffer_local_map, Ctl ('g'),
 		      "abort-recursive-edit");
