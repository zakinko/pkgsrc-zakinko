$NetBSD$

Fix build on NetBSD (SO_PEERCRED) and on FreeBSD/DragonFly (SO_PEERPIDFD).
https://github.com/polkit-org/polkit/pull/624

This replaces the pkgsrc patch of the same name, which carries only the
SO_PEERCRED half.  That is enough for NetBSD but not for FreeBSD, where

  polkitagenthelper-pam.c:156:48: error: use of undeclared identifier 'ENODATA'

The file defines SO_PEERPIDFD itself when the system does not, with no
platform test at all, so the pidfd block is compiled everywhere.  Inside
it, errno is compared against ENODATA, which FreeBSD does not have (and
NetBSD does, which is why only FreeBSD fails).  FreeBSD ports solves it
in sysutils/polkit by making that define Linux-only and wrapping the
block, and that half is taken from there.

Regenerated mechanically: the two sets of changes were applied to the
pristine 127 source and diffed, rather than the hunks being merged by
hand.

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
