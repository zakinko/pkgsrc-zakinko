$NetBSD$

Replace gets() in the [TESTRM] test driver with fgets(), backporting

  From e90a457c46ca4c6a231a422b9b30f5e0d0f9d1c1 Mon Sep 17 00:00:00 2001
  From: Eli Zaretskii <eliz@gnu.org>
  Date: Thu, 8 Sep 2022
  Subject: * src/xrdb.c (main) [TESTRM]: Replace gets with fgets.

gets() has no bound and cannot be used safely; it was removed from C11.
The call is inside the TESTRM stand-alone driver, which is not compiled
into Emacs (the built binary has no gets symbol), so this changes no
shipped code -- it is here to match upstream and to keep the source
clean, since gets() is a hard error with newer toolchains.

--- src/xrdb.c.orig
+++ src/xrdb.c
@@ -718,14 +718,14 @@
       char query_class[90];
 
       printf ("Name: ");
-      gets (query_name);
+      fgets (query_name, 90, stdin);
 
       if (strlen (query_name))
 	{
 	  char *value;
 
 	  printf ("Class: ");
-	  gets (query_class);
+	  fgets (query_class, 90, stdin);
 
 	  value = x_get_string_resource (xdb, query_name, query_class);
 
