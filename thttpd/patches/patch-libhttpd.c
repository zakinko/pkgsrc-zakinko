$NetBSD$

Not a CVE: the same length-1 indexing shape as patch-CVE-2007-0158, in
the PATH_INFO trimming.  When pathinfo is the whole of origfilename, i
is 0 and origfilename[i-1] would read before the buffer.  I did not find
a request that reaches it, so this is guarded rather than fixed for a
demonstrated bug.  FreeBSD ports and Debian both carry the same change.

--- libhttpd.c.orig
+++ libhttpd.c
@@ -2351,8 +2351,13 @@
 	{
 	int i;
 	i = strlen( hc->origfilename ) - strlen( hc->pathinfo );
-	if ( i > 0 && strcmp( &hc->origfilename[i], hc->pathinfo ) == 0 )
-	    hc->origfilename[i - 1] = '\0';
+	if ( i >= 0 && strcmp( &hc->origfilename[i], hc->pathinfo ) == 0 )
+	    {
+	    if ( i == 0 )
+		hc->origfilename[0] = '\0';
+	    else
+		hc->origfilename[i - 1] = '\0';
+	    }
 	}
 
     /* If the expanded filename is an absolute path, check that it's still
