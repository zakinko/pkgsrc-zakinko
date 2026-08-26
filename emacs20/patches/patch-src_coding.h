$NetBSD$

Declare code_convert_string_norecord, which returns a Lisp_Object.

ENCODE_FILE and DECODE_FILE call it and nothing declares it, so on LP64
the implicit int return truncates the 64-bit Lisp_Object to 32 bits and
the type tag (bits 60-62) is lost.  Most callers hand the result straight
to XSTRING, which masks the tag off anyway, so they survive; the one in
openp does not.

openp gets ENCODE_FILE from the Mule 4.1b distribution patch:

	filename = ENCODE_FILE (filename);

and then passes filename to Ffind_file_name_handler, whose CHECK_STRING
sees an untagged pointer as an integer:

	Wrong type argument: stringp, 8510432

So every relative load fails as soon as a non-nil file name coding system
is in force.  set-language-environment sets one through
prefer-coding-system, which is why "Japanese", "Chinese-GB" and "Korean"
die while "Greek" and "Latin-1", which pull in no extra features, do not.

Emacs 21 declares it; this is its line, in its place.

--- src/coding.h.orig	2026-08-26 04:33:33.562475397 +0000
+++ src/coding.h
@@ -563,6 +563,8 @@
 extern char *get_conversion_buffer P_ ((int));
 extern int setup_coding_system P_ ((Lisp_Object, struct coding_system *));
 extern void setup_raw_text_coding_system P_ ((struct coding_system *));
+extern Lisp_Object code_convert_string_norecord P_ ((Lisp_Object, Lisp_Object,
+						     int));
 extern Lisp_Object Qcoding_system, Qeol_type, Qcoding_category_index;
 extern Lisp_Object Qraw_text, Qemacs_mule;
 extern Lisp_Object Qbuffer_file_coding_system;
