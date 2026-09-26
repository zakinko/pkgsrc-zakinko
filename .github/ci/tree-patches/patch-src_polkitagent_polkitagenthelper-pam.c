$NetBSD$

Fix build where ENODATA is missing, such as FreeBSD, and keep the
NetBSD fix.

Two upstream commits, both after polkit 127:

  066b55bf2e2b  polkitagenthelper-pam.c: ifdef out the socket activation
                functionality
  72c28782b17e  Fix build on systems without SO_PEERCRED.

The tree's patch of this name is 72c28782b17e, hunk for hunk.  What is
missing is the other one.  polkit defines SO_PEERPIDFD itself when the
system does not, with no platform test, so the socket-activation block is
compiled everywhere; inside it errno is compared against ENODATA, which
FreeBSD, DragonFly and OpenBSD do not have:

  polkitagenthelper-pam.c:156:48: error: use of undeclared identifier 'ENODATA'

NetBSD has ENODATA, which is why its build was fine without this half.
066b55bf2e2b
makes the fallback define Linux-only and wraps the block in
#ifdef SO_PEERPIDFD.

Both were applied to the pristine 127 source with patch(1) and the result
diffed, rather than the hunks being merged by hand.

--- src/polkitagent/polkitagenthelper-pam.c.orig
+++ src/polkitagent/polkitagenthelper-pam.c
@@ -38,7 +38,7 @@
 #    define SO_PEERPIDFD 0x404B
 #  elif defined(__sparc__)
 #    define SO_PEERPIDFD 0x0056
-#  else
+#  elif defined(__linux__)
 #    define SO_PEERPIDFD 77
 #  endif
 #endif
@@ -137,11 +137,14 @@
       goto error;
     }
 
+#ifdef SO_PEERPIDFD
   /* We are socket activated and the socket has been set up as stdio/stdout, read user from it */
   if (argv[1] != NULL && strcmp (argv[1], "--socket-activated") == 0)
     {
       socklen_t socklen = sizeof(int);
+#ifdef SO_PEERCRED
       struct ucred ucred;
+#endif
 
       user_to_auth_free = read_cookie (argc, argv);
       if (!user_to_auth_free)
@@ -165,8 +168,12 @@
           goto error;
         }
 
+#ifdef SO_PEERCRED
       socklen = sizeof(ucred);
       rc = getsockopt(STDIN_FILENO, SOL_SOCKET, SO_PEERCRED, &ucred, &socklen);
+#else
+      rc = -1;
+#endif
       if (rc < 0)
         {
           syslog (LOG_ERR, "Unable to get credentials from socket");
@@ -174,9 +181,12 @@
           goto error;
         }
 
+#ifdef SO_PEERCRED
       uid = ucred.uid;
+#endif
     }
   else
+#endif
     user_to_auth = argv[1];
 
   cookie = read_cookie (argc, argv);
