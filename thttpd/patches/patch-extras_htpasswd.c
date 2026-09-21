$NetBSD$

Same class as the expand_symlinks()/auth_check2() underflows patched in
patch-libhttpd.c: fgets() is not checked and pass[strlen(pass)-1] reads
before the buffer when it fails (pass is left uninitialized) or when the
first byte read is a NUL.

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
