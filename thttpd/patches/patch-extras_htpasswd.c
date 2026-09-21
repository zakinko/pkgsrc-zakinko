$NetBSD$

Not a CVE: the same length-1 indexing shape as patch-CVE-2007-0158, in
the htpasswd utility.  fgets() is not checked, so pass is left
uninitialised when it fails, and a leading NUL byte leaves strlen() at
0; either way pass[strlen(pass)-1] reads before the buffer.  Both paths
fire under AddressSanitizer on the routine extracted unchanged from
2.29 (empty stdin, and a line starting with a NUL byte).

This is a local tool reading its own stdin, not the server, so it is
kept apart from the CVE patches.  Neither FreeBSD ports nor Debian
patches this; their htpasswd changes are elsewhere in the file.

--- extras/htpasswd.c.orig
+++ extras/htpasswd.c
@@ -112,8 +112,13 @@
 
     if ( ! isatty( fileno( stdin ) ) )
 	{
-	(void) fgets( pass, sizeof(pass), stdin );
-	if ( pass[strlen(pass) - 1] == '\n' )
+	/* fgets() can fail, leaving pass uninitialized, and a NUL byte on
+	** stdin leaves strlen() at 0; either way pass[strlen(pass)-1] would
+	** read before the buffer.
+	*/
+	if ( fgets( pass, sizeof(pass), stdin ) == (char*) 0 )
+	    pass[0] = '\0';
+	if ( pass[0] != '\0' && pass[strlen(pass) - 1] == '\n' )
 	    pass[strlen(pass) - 1] = '\0';
 	pw = pass;
 	}
