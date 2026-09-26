$NetBSD$

code_convert_string_norecord returns a Lisp_Object but had no prototype,
so the six files that reach it through ENCODE_FILE and DECODE_FILE
(fileio.c, lread.c, dired.c, callproc.c, filelock.c, process.c) called
it as an int-returning function.  On a 64-bit host the returned pointer
was truncated, and as soon as file-name-coding-system was set -- which
set-language-environment "Japanese" does -- every insert-file-contents
and load failed with "Wrong type argument: stringp, <number>".

--- src/coding.h.orig	2000-03-13 05:13:15.000000000 +0000
+++ src/coding.h
@@ -563,6 +563,7 @@
 extern char *get_conversion_buffer P_ ((int));
 extern int setup_coding_system P_ ((Lisp_Object, struct coding_system *));
 extern void setup_raw_text_coding_system P_ ((struct coding_system *));
+extern Lisp_Object code_convert_string_norecord P_ ((Lisp_Object, Lisp_Object, int));
 extern Lisp_Object Qcoding_system, Qeol_type, Qcoding_category_index;
 extern Lisp_Object Qraw_text, Qemacs_mule;
 extern Lisp_Object Qbuffer_file_coding_system;
