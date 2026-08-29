$NetBSD: patch-ca,v 1.1 2005/02/09 16:09:43 drochner Exp $

error() takes a printf format.  Passing the message as the format string means
any % in it is read as a conversion, and the text here comes from the POP
server, so a hostile server can walk the stack.  Modern compilers refuse this
outright with -Wformat-security.

--- lib-src/movemail.c.orig	2005-02-09 16:55:15.000000000 +0100
+++ lib-src/movemail.c
@@ -765,7 +765,7 @@ popmail (user, outfile, preserve, passwo
       mbx_delimit_begin (mbf);
       if (pop_retr (server, i, mbf) != OK)
 	{
-	  error (Errmsg);
+	  error ("%s", Errmsg);
 	  close (mbfi);
 	  return (1);
 	}
