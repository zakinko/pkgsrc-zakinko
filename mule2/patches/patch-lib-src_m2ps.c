$NetBSD$

Declare what this program calls, so nothing is reached through an implicit
declaration -- the form C99 removed and clang 16 and gcc 14 reject.  The
standard functions come through their headers, with the file's own
hand-written declarations of them removed where they disagreed; the tree's
own come through the type their definition carries.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

--- lib-src/m2ps.c.orig
+++ lib-src/m2ps.c
@@ -52,6 +52,30 @@
 
 #include <../src/paths.h>
 
+/* Declare what this program calls: the standard functions through their
+   headers, the tree's own through the type their definition carries.
+   Reaching either through an implicit declaration is what C99 removed. */
+#include <stdlib.h>
+
+/* Declare the standard functions this file calls. */
+#include <string.h>
+extern int bdf_initialize ();
+extern int bdf_load_font ();
+extern int bdf_load_glyph ();
+extern int ccl_driver ();
+extern int control_char ();
+extern int fatal1 ();
+extern int get_line ();
+extern int invalid_char ();
+extern int mulelib_initialize ();
+extern int ps_bop ();
+extern int ps_bot ();
+extern int ps_eop ();
+extern int ps_eot ();
+extern int ps_newfont ();
+extern int ps_newglyph ();
+extern int ps_setfont ();
+
 static char *m2ps_version = "2.2";
 
 #ifndef PSHeader
@@ -124,7 +148,7 @@
 /* GLOBAL VARIABLES */
 int clm, row, current_lc;
 
-set_font(lc)
+int set_font(lc)
      int lc;
 {				/* 93.5.7, 94.11.29 by K.Handa -- Big change */
   if (FONT_LOADED (lc) == 0) {
@@ -140,7 +164,7 @@
   }
 }
 
-renew_font(lc)
+int renew_font(lc)
      int lc;
 {
   bzero(((font_extra *)font[lc & 0x7F].extra)->new, 256 * (sizeof (char)));
@@ -148,7 +172,7 @@
 
 /* Load specified glyph, then return the index to glyph.  Note the index
    is within the range of [0,255].  Return -1 if error. */
-set_glyph1(lc, c)
+int set_glyph1(lc, c)
      int lc, c;
 {
   if (!DEFINED1(lc, c)) {
@@ -161,7 +185,7 @@
   return c;
 }
 
-find_encoding(fontp, lc, c)
+int find_encoding(fontp, lc, c)
      font_struct *fontp;
      int lc, c;
 {
@@ -189,7 +213,7 @@
 /* Load specified glyph, replacing previously loaded glyph if necessary,
    then return the index to glyph.  Note the index is within the range
    of [0,255].  Return -1 if error. */
-set_glyph2(lc, c)
+int set_glyph2(lc, c)
      int lc, c;
 {
   int code;
@@ -212,7 +236,7 @@
   return code;
 }
 
-swap_buf(buf, from, to)
+int swap_buf(buf, from, to)
      unsigned char *buf;
      int from, to;
 {
@@ -229,7 +253,7 @@
   bcopy(buf2, buf + from, to - from);
 }
 
-textmode()
+int textmode()
 {
   register int i, j, k, c, lc;
   char buf[1024];		/* 92.11.6 by K.Shibata */
@@ -406,7 +430,7 @@
   ps_eot();
 }
 
-control_char(c)
+int control_char(c)
      int c;
 {
   c += '@';
@@ -417,7 +441,7 @@
   }
 }    
 
-invalid_char(c)
+int invalid_char(c)
      int c;
 {
   int i;
@@ -434,7 +458,7 @@
   }
 }
 
-main(argc, argv)
+int main(argc, argv)
      int argc;
      char *argv[];
 {
@@ -502,7 +526,7 @@
 /* PostScript staffs */
 /*********************/
 
-ps_bot()
+int ps_bot()
 {
   int c;
   FILE *fp;
@@ -521,7 +545,7 @@
   printf("/ShortMemory %s def\n", (shortmemory ? "true" : "false"));
 }
 
-ps_eot()
+int ps_eot()
 {
   printf("end\n");
 }
@@ -529,7 +553,7 @@
 /* Define new PS font for a leading char LC.
    No_cache flag is for the fonts be modified (replacing the glyphs, etc.)
    at execution time. */
-ps_newfont(lc)
+int ps_newfont(lc)
      int lc;
 {
   font_struct *fontp = &font[lc & 0x7F];
@@ -542,13 +566,13 @@
 	 (fontp->bytes == 1 ? "true" : "false"));
 }
 
-ps_setfont(lc)
+int ps_setfont(lc)
      int lc;
 {
   printf("F%02x f\n", lc);
 }
 
-ps_newglyph(encoding, glyph)
+int ps_newglyph(encoding, glyph)
      int encoding;
      glyph_struct *glyph;
 {
@@ -567,7 +591,7 @@
 	 bitmap);
 }
 
-ps_bop()
+int ps_bop()
 {
   int lc;
 
@@ -581,7 +605,7 @@
   }
 }
 
-ps_eop()
+int ps_eop()
 {
   printf("ep\n");
 }
