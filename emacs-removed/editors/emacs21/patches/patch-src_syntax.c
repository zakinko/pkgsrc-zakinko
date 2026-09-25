$NetBSD: patch-src_syntax.c,v 1.1 2016/05/03 09:41:20 wiz Exp $

inc_bytepos and dec_bytepos are used only in this file.  Without static, INLINE
leaves an external definition in every object that includes the header, and the
link fails on duplicate symbols.  Same as the first half of patch-src_dispnew.c.

--- src/syntax.c.orig	2001-09-08 14:30:12.000000000 +0000
+++ src/syntax.c
@@ -316,7 +316,7 @@ char_quoted (charpos, bytepos)
 /* Return the bytepos one character after BYTEPOS.
    We assume that BYTEPOS is not at the end of the buffer.  */
 
-INLINE int
+static INLINE int
 inc_bytepos (bytepos)
      int bytepos;
 {
@@ -330,7 +330,7 @@ inc_bytepos (bytepos)
 /* Return the bytepos one character before BYTEPOS.
    We assume that BYTEPOS is not at the start of the buffer.  */
 
-INLINE int
+static INLINE int
 dec_bytepos (bytepos)
      int bytepos;
 {
