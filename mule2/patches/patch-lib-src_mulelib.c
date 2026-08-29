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

--- lib-src/mulelib.c.orig
+++ lib-src/mulelib.c
@@ -16,6 +16,13 @@
 
 #include <../src/paths.h>
 
+/* Declare what this program calls: the standard functions through their
+   headers, the tree's own through the type their definition carries.
+   Reaching either through an implicit declaration is what C99 removed. */
+extern int init_charset_once ();
+extern int set_ccl_program ();
+extern int update_mc_table ();
+
 char *mule_library_version = "2.2";
 
 int mule_error;
@@ -72,7 +79,7 @@
   }
 }
 
-get_line(buf, size, fp)
+int get_line(buf, size, fp)
      char *buf;
      int size;
      FILE *fp;
@@ -91,28 +98,28 @@
 #define PROCEED_CHAR(c) \
   if (!(p1 = (char *)index(p0, c))) goto invalid_entry
 
-warning1(format, arg1)
+int warning1(format, arg1)
      char *format;
      int arg1;
 {
   fprintf(stderr, format, arg1);
 }
 
-warning2(format, arg1, arg2)
+int warning2(format, arg1, arg2)
      char *format;
      int arg1, arg2;
 {
   fprintf(stderr, format, arg1, arg2);
 }
 
-warning3(format, arg1, arg2, arg3)
+int warning3(format, arg1, arg2, arg3)
      char *format;
      int arg1, arg2, arg3;
 {
   fprintf(stderr, format, arg1, arg2, arg3);
 }
 
-fatal1(arg)
+int fatal1(arg)
      char *arg;
 {
   fprintf(stderr, "%s", arg);
@@ -127,7 +134,7 @@
 char *font_name[128];
 int font_encoding[128];
 
-set_charsets_param(line)
+int set_charsets_param(line)
      char *line;
 {
   char *p0 = line, *p1;
@@ -190,7 +197,7 @@
   return -1;
 }
  
-set_ccl_program_param(line)
+int set_ccl_program_param(line)
      char *line;
 {
   int lc, len, i, j;
@@ -212,7 +219,7 @@
   return 0;
 }
 
-charsets_initialize(charsets)
+int charsets_initialize(charsets)
      char *charsets;
 {
   FILE *fp;
@@ -254,7 +261,7 @@
 int n_base_coding_system = 0;
 int n_coding_system;
 
-set_coding_system_param(line, cs)
+int set_coding_system_param(line, cs)
      char *line;
      coding_type *cs;
 {
@@ -354,7 +361,7 @@
   "*coding-category-big5*",
   "*coding-category-bin*"};
 
-set_coding_category(line, priority)
+int set_coding_category(line, priority)
      char *line;
      int priority;
 {
@@ -380,7 +387,7 @@
   return -1;
 } 
 
-codings_initialize(codings)
+int codings_initialize(codings)
      char *codings;
 {
   FILE *fp;
@@ -452,7 +459,7 @@
 }
 
 static
-find_coding(str)
+int find_coding(str)
      char *str;
 {
   int i;
@@ -477,7 +484,7 @@
   return -1;
 }
 
-encode_code(code, mccode)
+int encode_code(code, mccode)
      Lisp_Object code;
      coding_type *mccode;
 {
@@ -489,7 +496,7 @@
     CODE_TYPE_SET (mccode, NOCONV);
 }
 
-set_coding_system(inname, incode, outname, outcode)
+int set_coding_system(inname, incode, outname, outcode)
      char *inname, *outname;
      coding_type *incode, *outcode;
 {
@@ -514,7 +521,7 @@
   return 0;
 }
 
-code_conversion(incode, inbuf, insize, outcode, outbuf, outsize)
+int code_conversion(incode, inbuf, insize, outcode, outbuf, outsize)
      coding_type *incode, *outcode;
      char *inbuf, *outbuf;
      int insize, outsize;
@@ -626,7 +633,7 @@
  * INITIALIZER *
  ***************/
 
-mulelib_initialize(argc, argv, charsets, codings)
+int mulelib_initialize(argc, argv, charsets, codings)
      int argc;
      char **argv, *charsets, *codings;
 {
