$NetBSD$

CVE-2007-0158: expand_symlinks() trims a trailing slash with
lnk[linklen-1] without checking linklen.  An empty symlink target in the
served tree makes readlink() return 0, so lnk[-1] is read (and, if it is a
slash, written), underflowing the stack buffer.  Guard on linklen > 0.

CVE-2012-5640: auth_check2() passed the result of crypt() straight to
strcmp().  crypt() returns NULL for a salt it does not understand, and the
salt comes from a user-written .htpasswd, so a bad line crashed the server
on the next request for that directory.

CVE-2009-4491: make_log_entry() wrote the request URL, Referer and
User-Agent to the log file and to syslog as the client sent them, so a
request could put terminal escape sequences into the log.  Control
characters are now written as \xHH.

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
@@ -3904,12 +3913,45 @@
     }
 
 
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
+    }
+
+
 static void
 make_log_entry( httpd_conn* hc, struct timeval* nowP )
     {
     char* ru;
     char url[305];
     char bytes[40];
+    char eurl[305 * 4];
+    char eref[200 * 4 + 1];
+    char eua[200 * 4 + 1];
+    char eru[80 * 4 + 1];
 
     if ( hc->hs->no_log )
 	return;
@@ -3922,7 +3964,7 @@
 
     /* Format remote user. */
     if ( hc->remoteuser[0] != '\0' )
-	ru = hc->remoteuser;
+	ru = log_escape( eru, sizeof(eru), hc->remoteuser );
     else
 	ru = "-";
     /* If we're vhosting, prepend the hostname to the url.  This is
@@ -3937,6 +3979,9 @@
     else
 	(void) my_snprintf( url, sizeof(url),
 	    "%.200s", hc->encodedurl );
+    (void) log_escape( eurl, sizeof(eurl), url );
+    (void) log_escape( eref, sizeof(eref), hc->referrer );
+    (void) log_escape( eua, sizeof(eua), hc->useragent );
     /* Format the bytes. */
     if ( hc->bytes_sent >= 0 )
 	(void) my_snprintf(
@@ -3985,8 +4030,8 @@
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
@@ -3995,8 +4040,8 @@
 	syslog( LOG_INFO,
 	    "%.80s - %.80s \"%.80s %.200s %.80s\" %d %s \"%.200s\" \"%.200s\"",
 	    httpd_ntoa( &hc->client_addr ), ru,
-	    httpd_method_str( hc->method ), url, hc->protocol,
-	    hc->status, bytes, hc->referrer, hc->useragent );
+	    httpd_method_str( hc->method ), eurl, hc->protocol,
+	    hc->status, bytes, eref, eua );
     }
 
 
