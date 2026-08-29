$NetBSD: patch-src_insdel.c,v 1.1 2013/04/21 15:39:59 joerg Exp $

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

--- src/insdel.c.orig
+++ src/insdel.c
@@ -45,7 +45,7 @@
 /* Move gap to position `pos'.
    Note that this can quit!  */
 
-move_gap (pos)
+int move_gap (pos)
      int pos;
 {
   if (pos < GPT)
@@ -230,7 +230,7 @@
   adjust_markers2 (from, to, amount, MARKER_ALL_TYPE);
 }
 
-adjust_markers2 (from, to, amount, marker_type)
+int adjust_markers2 (from, to, amount, marker_type)
      int from, to;
      register int amount, marker_type;
 {
@@ -272,13 +272,14 @@
    current set of intervals.  */
 static void
 adjust_point (amount)
+     int amount;
 {
   current_buffer->text.pt += amount;
 }
 
 /* Make the gap INCREMENT characters longer.  */
 
-make_gap (increment)
+int make_gap (increment)
      int increment;
 {
   unsigned char *result;
@@ -323,9 +324,9 @@
    DO NOT use this for the contents of a Lisp string!
    prepare_to_modify_buffer could relocate the string.  */
 
-insert (string, length)
+int insert (string, length)
      register unsigned char *string;
-     register length;
+     register int length;
 {
   if (length > 0)
     {
@@ -341,9 +342,9 @@
     }
 }
 
-insert_and_inherit (string, length)
+int insert_and_inherit (string, length)
      register unsigned char *string;
-     register length;
+     register int length;
 {
   if (length > 0)
     {
@@ -362,7 +363,7 @@
 static void
 insert_1 (string, length, inherit)
      register unsigned char *string;
-     register length;
+     register int length;
      int inherit;
 {
   register Lisp_Object temp;
@@ -415,7 +416,7 @@
    before we bcopy the stuff into the buffer, and relocate the string
    without insert noticing.  */
 
-insert_from_string (string, pos, length, inherit)
+int insert_from_string (string, pos, length, inherit)
      Lisp_Object string;
      register int pos, length;
      int inherit;
@@ -503,7 +504,7 @@
    Don't use this function to insert part of a Lisp string,
    since gc could happen and relocate it.  */
 
-insert_before_markers (string, length)
+int insert_before_markers (string, length)
      unsigned char *string;
      register int length;
 {
@@ -516,7 +517,7 @@
     }
 }
 
-insert_before_markers_and_inherit (string, length)
+int insert_before_markers_and_inherit (string, length)
      unsigned char *string;
      register int length;
 {
@@ -531,7 +532,7 @@
 
 /* Insert part of a Lisp string, relocating markers after.  */
 
-insert_from_string_before_markers (string, pos, length, inherit)
+int insert_from_string_before_markers (string, pos, length, inherit)
      Lisp_Object string;
      register int pos, length;
      int inherit;
@@ -550,7 +551,7 @@
    Don't use this function to insert part of a Lisp string,
    since gc could happen and relocate it.  */
 
-insert_after_markers (string, length)
+int insert_after_markers (string, length)
      unsigned char *string;
      register int length;
 {
@@ -561,7 +562,7 @@
     }
 }
 
-insert_after_markers_and_inherit (string, length)
+int insert_after_markers_and_inherit (string, length)
      unsigned char *string;
      register int length;
 {
@@ -574,7 +575,7 @@
 
 /* Insert part of a Lisp string.  */
 
-insert_from_string_after_markers (string, pos, length, inherit)
+int insert_from_string_after_markers (string, pos, length, inherit)
      Lisp_Object string;
      register int pos, length;
      int inherit;
@@ -589,17 +590,16 @@
 
 /* Delete characters in current buffer
    from FROM up to (but not including) TO.  */
+void del_range_1 (int from, int to, int prepare);
 
-del_range (from, to)
-     register int from, to;
+void del_range (int from, int to)
 {
-  return del_range_1 (from, to, 1);
+  del_range_1 (from, to, 1);
 }
 
 /* Like del_range; PREPARE says whether to call prepare_to_modify_buffer.  */
 
-del_range_1 (from, to, prepare)
-     register int from, to, prepare;
+void del_range_1 (int from, int to, int prepare)
 {
   register int numdel;
 
@@ -652,7 +652,7 @@
    to END.  This checks the read-only properties of the region, calls
    the necessary modification hooks, and warns the next redisplay that
    it should pay attention to that area.  */
-modify_region (buffer, start, end)
+int modify_region (buffer, start, end)
      struct buffer *buffer;
      int start, end;
 {
@@ -682,7 +682,7 @@
    verify that the text to be modified is not read-only, and call
    any modification properties the text may have. */
 
-prepare_to_modify_buffer (start, end)
+int prepare_to_modify_buffer (start, end)
      Lisp_Object start, end;
 {
   if (!NILP (current_buffer->read_only))
@@ -747,7 +747,7 @@
    START and END are the bounds of the text to be changed,
    as Lisp objects.  */
 
-signal_before_change (start, end)
+int signal_before_change (start, end)
      Lisp_Object start, end;
 {
   /* If buffer is unmodified, run a special hook for that case.  */
@@ -817,7 +817,7 @@
    (Not the whole buffer; just the part that was changed.)
    LENINS is the number of characters in the changed text.  */
 
-signal_after_change (pos, lendel, lenins)
+int signal_after_change (pos, lendel, lenins)
      int pos, lendel, lenins;
 {
   if (!NILP (Vafter_change_function))
