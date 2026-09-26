$NetBSD: patch-glib_glib-unix.c,v 1.2 2026/04/24 08:02:58 mrg Exp $

Fix build on NetBSD and DragonFly.

g_unix_fd_query_path() sends DragonFly down the FreeBSD branch, which uses
fcntl(F_KINFO) and struct kinfo_file.  DragonFly has neither, so glib-unix.c
does not compile there:

  glib-unix.c:975:18: error: 'F_KINFO' undeclared

DragonFly has had fcntl(F_GETPATH) since 2021 (commit 36f3145a09, in 6.4),
filling a caller's MAXPATHLEN buffer with a NUL-terminated path the way
macOS, NetBSD and OpenBSD do, so it belongs in that branch instead.

--- glib/glib-unix.c.orig
+++ glib/glib-unix.c
@@ -49,6 +49,7 @@
 #include <fcntl.h>
 #include <stdlib.h>   /* for fdwalk */
 #include <string.h>
+#include <sys/param.h> /* for MAXPATHLEN */
 #include <sys/types.h>
 #include <pwd.h>
 #include <unistd.h>
@@ -967,7 +968,7 @@
   g_free (proc_path);
 
   return g_steal_pointer (&path);
-#elif defined (__FreeBSD__) || defined(__DragonFly__)
+#elif defined (__FreeBSD__)
   struct kinfo_file kf = {0};
 
   kf.kf_structsize = sizeof (kf);
@@ -982,7 +983,9 @@
     }
 
   return g_strdup (kf.kf_path);
-#elif defined (__APPLE__) || defined (__NetBSD__) || defined (__OpenBSD__)
+#elif defined (__APPLE__) || defined (__NetBSD__) || defined (__OpenBSD__) || \
+      defined (__DragonFly__)
+# ifdef F_GETPATH
   char file_path[MAXPATHLEN] = {0};
 
   if (fcntl (fd, F_GETPATH, file_path) < 0)
@@ -996,6 +999,11 @@
     }
 
   return g_strdup (file_path);
+# else
+  g_set_error (error, G_FILE_ERROR, G_FILE_ERROR_NOSYS,
+               "g_unix_fd_query_path() not supported");
+  return NULL;
+# endif
 #elif defined (__GNU__)
   /*
    * Hurd allows to open("/dev/fd/%u") to open the very same fd, but it's not
