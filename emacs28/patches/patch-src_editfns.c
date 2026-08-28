$NetBSD$

	b560ce3560  Avoid assertion violations in STRING_CHAR

Second half of the change described in patch-src_xdisp.c.

--- src/editfns.c.orig
+++ src/editfns.c
@@ -3468,7 +3468,9 @@
 		      || conversion == 'o' || conversion == 'x'
 		      || conversion == 'X'))
 	    error ("Invalid format operation %%%c",
-		   STRING_CHAR ((unsigned char *) format - 1));
+		   multibyte_format
+		   ? STRING_CHAR ((unsigned char *) format - 1)
+		   : *((unsigned char *) format - 1));
 	  else if (! (FIXNUMP (arg) || ((BIGNUMP (arg) || FLOATP (arg))
 					&& conversion != 'c')))
 	    error ("Format specifier doesn't match argument type");
