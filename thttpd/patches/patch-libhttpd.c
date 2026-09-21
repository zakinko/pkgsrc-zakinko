$NetBSD$

Fix three CVEs that audit-packages reports against thttpd 2.29, the last
release ACME shipped (2018).  A 2.30 is listed in the upstream changelog
but has never been released as a tarball.

CVE-2007-0158 (buffer underflow in expand_symlinks()).  Three places
index with length-1 without checking the length:

  - with no_symlink_check (chroot mode) and a path of only slashes, the
    trailing-slash trim drives checkedlen to 0 and then reads
    checked[-1]; stat("/") always succeeds, so "/" reaches it;
  - with an empty path, rest[restlen-1] reads before the buffer;
  - with a zero-length symlink target in the served tree, readlink()
    returns 0 and lnk[linklen-1] reads before the stack buffer.

All three fire under AddressSanitizer on the routine extracted unchanged
from 2.29, and are clean once guarded.  FreeBSD ports carries the
checkedlen/restlen and origfilename guards; the readlink() case is the
fix ACME lists for the unreleased 2.30 ("off-by-one illegal memory
access in expand_symlinks()").

CVE-2012-5640 (crypt() NULL dereference).  auth_check2() compares the
result of crypt() without a NULL check; the salt comes from a
user-written .htpasswd.  crypt() returns NULL on glibc and illumos.
Also listed for 2.30.

CVE-2009-4491 (log injection).  make_log_entry() writes the request URL,
Referer and User-Agent to the log and to syslog as the client sent them.
Control characters are written as \xHH.  Not in the 2.30 changelog and
not carried by any other packaging I found.

--- libhttpd.c.orig
+++ libhttpd.c
@@ -172,6 +172,7 @@
 static int cgi( httpd_conn* hc );
 static int really_start_request( httpd_conn* hc, struct timeval* nowP );
 static void make_log_entry( httpd_conn* hc, struct timeval* nowP );
+static char* log_escape( char* dst, size_t dstsize, const char* src );
 static int check_referrer( httpd_conn* hc );
 static int really_check_referrer( httpd_conn* hc );
 static int sockaddr_check( httpd_sockaddr* saP );
@@ -1030,6 +1031,7 @@
     FILE* fp;
     char line[500];
     char* cryp;
+    char* cryp2;
     static char* prevauthpath;
     static size_t maxprevauthpath = 0;
     static time_t prevmtime;
@@ -1082,8 +1084,12 @@
 	 sb.st_mtime == prevmtime &&
 	 strcmp( authinfo, prevuser ) == 0 )
 	{
-	/* Yes.  Check against the cached encrypted password. */
-	if ( strcmp( crypt( authpass, prevcryp ), prevcryp ) == 0 )
+	/* Yes.  Check against the cached encrypted password.  crypt()
+	** returns NULL for a salt it does not understand, and the password
+	** file is user-supplied, so check before comparing.
+	*/
+	cryp = crypt( authpass, prevcryp );
+	if ( cryp != (char*) 0 && strcmp( cryp, prevcryp ) == 0 )
 	    {
 	    /* Ok! */
 	    httpd_realloc_str(
@@ -1131,8 +1137,9 @@
 	    {
 	    /* Yes. */
 	    (void) fclose( fp );
-	    /* So is the password right? */
-	    if ( strcmp( crypt( authpass, cryp ), cryp ) == 0 )
+	    /* So is the password right?  As above, crypt() may return NULL. */
+	    cryp2 = crypt( authpass, cryp );
+	    if ( cryp2 != (char*) 0 && strcmp( cryp2, cryp ) == 0 )
 		{
 		/* Ok! */
 		httpd_realloc_str(
@@ -1486,7 +1493,7 @@
 	    httpd_realloc_str( &checked, &maxchecked, checkedlen );
 	    (void) strcpy( checked, path );
 	    /* Trim trailing slashes. */
-	    while ( checked[checkedlen - 1] == '/' )
+	    while ( checkedlen > 0 && checked[checkedlen - 1] == '/' )
 		{
 		checked[checkedlen - 1] = '\0';
 		--checkedlen;
@@ -1505,7 +1512,7 @@
     restlen = strlen( path );
     httpd_realloc_str( &rest, &maxrest, restlen );
     (void) strcpy( rest, path );
-    if ( rest[restlen - 1] == '/' )
+    if ( restlen > 0 && rest[restlen - 1] == '/' )
 	rest[--restlen] = '\0';         /* trim trailing slash */
     if ( ! tildemapped )
 	/* Remove any leading slashes. */
@@ -1623,7 +1630,9 @@
 	    return (char*) 0;
 	    }
 	lnk[linklen] = '\0';
-	if ( lnk[linklen - 1] == '/' )
+	/* CVE-2007-0158: an empty symlink target makes readlink() return 0,
+	** and lnk[linklen-1] then reads lnk[-1], underflowing the buffer. */
+	if ( linklen > 0 && lnk[linklen - 1] == '/' )
 	    lnk[--linklen] = '\0';     /* trim trailing slash */
 
 	/* Insert the link contents in front of the rest of the filename. */
@@ -2351,8 +2360,13 @@
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
@@ -3901,6 +3915,35 @@
 
     /* And return the status. */
     return r;
+    }
+
+
+/* Copy src into dst, replacing control characters with \xHH so that a
+** request cannot write terminal escape sequences into the log.  The
+** request line, Referer and User-Agent all come from the client as is.
+*/
+static char*
+log_escape( char* dst, size_t dstsize, const char* src )
+    {
+    static const char hex[] = "0123456789abcdef";
+    size_t i = 0;
+    unsigned char c;
+
+    for ( ; *src != '\0' && i + 4 < dstsize; ++src )
+	{
+	c = (unsigned char) *src;
+	if ( c < 0x20 || c == 0x7f )
+	    {
+	    dst[i++] = '\\';
+	    dst[i++] = 'x';
+	    dst[i++] = hex[c >> 4];
+	    dst[i++] = hex[c & 0xf];
+	    }
+	else
+	    dst[i++] = c;
+	}
+    dst[i] = '\0';
+    return dst;
     }
 
 
@@ -3910,6 +3953,10 @@
     char* ru;
     char url[305];
     char bytes[40];
+    char eurl[305 * 4];
+    char eref[200 * 4 + 1];
+    char eua[200 * 4 + 1];
+    char eru[80 * 4 + 1];
 
     if ( hc->hs->no_log )
 	return;
@@ -3922,7 +3969,7 @@
 
     /* Format remote user. */
     if ( hc->remoteuser[0] != '\0' )
-	ru = hc->remoteuser;
+	ru = log_escape( eru, sizeof(eru), hc->remoteuser );
     else
 	ru = "-";
     /* If we're vhosting, prepend the hostname to the url.  This is
@@ -3937,6 +3984,9 @@
     else
 	(void) my_snprintf( url, sizeof(url),
 	    "%.200s", hc->encodedurl );
+    (void) log_escape( eurl, sizeof(eurl), url );
+    (void) log_escape( eref, sizeof(eref), hc->referrer );
+    (void) log_escape( eua, sizeof(eua), hc->useragent );
     /* Format the bytes. */
     if ( hc->bytes_sent >= 0 )
 	(void) my_snprintf(
@@ -3985,8 +4035,8 @@
 	(void) fprintf( hc->hs->logfp,
 	    "%.80s - %.80s [%s] \"%.80s %.300s %.80s\" %d %s \"%.200s\" \"%.200s\"\n",
 	    httpd_ntoa( &hc->client_addr ), ru, date,
-	    httpd_method_str( hc->method ), url, hc->protocol,
-	    hc->status, bytes, hc->referrer, hc->useragent );
+	    httpd_method_str( hc->method ), eurl, hc->protocol,
+	    hc->status, bytes, eref, eua );
 #ifdef FLUSH_LOG_EVERY_TIME
 	(void) fflush( hc->hs->logfp );
 #endif
@@ -3995,8 +4045,8 @@
 	syslog( LOG_INFO,
 	    "%.80s - %.80s \"%.80s %.200s %.80s\" %d %s \"%.200s\" \"%.200s\"",
 	    httpd_ntoa( &hc->client_addr ), ru,
-	    httpd_method_str( hc->method ), url, hc->protocol,
-	    hc->status, bytes, hc->referrer, hc->useragent );
+	    httpd_method_str( hc->method ), eurl, hc->protocol,
+	    hc->status, bytes, eref, eua );
     }
 
 
