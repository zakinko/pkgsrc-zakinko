$NetBSD: patch-az,v 1.1 2007/06/11 13:38:43 markd Exp $

The relocating allocator measures the distance between two heap addresses.  On
LP64 that does not fit in an int, and the excess came out truncated or
negative, so memory that had been given back was not accounted for.

--- src/ralloc.c.orig	2001-02-20 01:19:40.000000000 +1300
+++ src/ralloc.c
@@ -328,7 +328,7 @@ static void
 relinquish ()
 {
   register heap_ptr h;
-  int excess = 0;
+  long excess = 0;
 
   /* Add the amount of space beyond break_value
      in all heaps which have extend beyond break_value at all.  */
