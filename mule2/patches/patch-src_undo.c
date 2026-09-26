$NetBSD: patch-src_undo.c,v 1.1 2013/04/21 15:40:00 joerg Exp $

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

--- src/undo.c.orig
+++ src/undo.c
@@ -41,8 +41,7 @@
    (It is possible to record an insertion before or after the fact
    because we don't need to record the contents.)  */
 
-record_insert (beg, length)
-     Lisp_Object beg, length;
+void record_insert(Lisp_Object beg, Lisp_Object length)
 {
   Lisp_Object lbeg, lend;
 
@@ -85,8 +84,7 @@
 /* Record that a deletion is about to take place,
    for LENGTH characters at location BEG.  */
 
-record_delete (beg, length)
-     int beg, length;
+void record_delete (int beg, int length)
 {
   Lisp_Object lbeg, lend, sbeg;
   int at_boundary;
@@ -132,7 +130,7 @@
    for LENGTH characters at location BEG.
    The replacement does not change the number of characters.  */
 
-record_change (beg, length)
+int record_change (beg, length)
      int beg, length;
 {
   record_delete (beg, length);
@@ -143,7 +141,7 @@
    Record the file modification date so that when undoing this entry
    we can tell whether it is obsolete because the file was saved again.  */
 
-record_first_change ()
+void record_first_change (void)
 {
   Lisp_Object high, low;
 
@@ -162,9 +160,7 @@
 /* Record a change in property PROP (whose old value was VAL)
    for LENGTH characters starting at position BEG in BUFFER.  */
 
-record_property_change (beg, length, prop, value, buffer)
-     int beg, length;
-     Lisp_Object prop, value, buffer;
+void record_property_change (int beg, int length, Lisp_Object prop, Lisp_Object value, Lisp_Object buffer)
 {
   Lisp_Object lbeg, lend, entry;
   struct buffer *obuf = current_buffer;
@@ -465,7 +461,7 @@
   return unbind_to (count, list);
 }
 
-syms_of_undo ()
+int syms_of_undo ()
 {
   Qinhibit_read_only = intern ("inhibit-read-only");
   staticpro (&Qinhibit_read_only);
