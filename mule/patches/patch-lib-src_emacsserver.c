$NetBSD$

Item 6: emacsserver put its listening socket at the predictable name
/tmp/esrv<uid>-<host> in a world-writable directory, and only tightened it
with chmod 0600 *after* bind(), leaving a window in which anyone could reach
it -- and another user could unlink or pre-create the name.

Put the socket inside a per-user directory instead, created 0700 and then
checked to be a real directory owned by us with no group or other bits, so
the name inside it cannot be pre-empted and there is no exposed window.  This
is the private-directory approach GNU Emacs adopted when it deleted
emacsserver.c in favour of the Lisp server (server-ensure-safe-dir /
server-socket-dir, commits 038de5b8 and 03ae35cf, 2002-2004).  The directory
is the same $TMPDIR/emacs<uid> the Lisp side uses (mule-user-temp-directory),
so the two stay consistent.

--- lib-src/emacsserver.c.orig	1995-01-01 00:00:00.000000000 +0000
+++ lib-src/emacsserver.c
@@ -53,10 +53,41 @@
 #include <sys/socket.h>
 #include <sys/signal.h>
 #include <sys/un.h>
+#include <sys/stat.h>
 #include <stdio.h>
 #include <errno.h>
 #include <stdlib.h>
 #include <string.h>
+
+/* Create DIR (mode 0700) if it does not exist, then insist that it is a real
+   directory owned by us with no group or other permission bits.  The socket
+   goes inside it, so its predictable name cannot be pre-empted by another
+   user and there is no bind()/chmod() window in which it is exposed.  This is
+   the same private-directory idea GNU Emacs moved its server socket to when it
+   deleted this program (server-ensure-safe-dir/server-socket-dir, commits
+   038de5b8 and 03ae35cf); Mule keeps emacsserver but borrows the technique,
+   and uses the very directory the Lisp side does (mule-user-temp-directory).  */
+
+static void
+ensure_safe_dir (dir)
+     char *dir;
+{
+  struct stat st;
+
+  if (mkdir (dir, 0700) < 0 && errno != EEXIST)
+    {
+      perror (dir);
+      exit (1);
+    }
+  if (lstat (dir, &st) < 0
+      || !S_ISDIR (st.st_mode)
+      || st.st_uid != geteuid ()
+      || (st.st_mode & 077) != 0)
+    {
+      fprintf (stderr, "emacsserver: the directory %s is unsafe\n", dir);
+      exit (1);
+    }
+}
 
 main ()
 {
@@ -89,8 +120,17 @@
     }
   server.sun_family = AF_UNIX;
 #ifndef SERVER_HOME_DIR
-  gethostname (system_name, sizeof (system_name));
-  sprintf (server.sun_path, "/tmp/esrv%d-%s", geteuid (), system_name);
+  {
+    char *tmpdir = getenv ("TMPDIR");
+    char dir[1024];
+
+    if (tmpdir == 0 || *tmpdir == 0)
+      tmpdir = "/tmp";
+    gethostname (system_name, sizeof (system_name));
+    sprintf (dir, "%s/emacs%d", tmpdir, (int) geteuid ());
+    ensure_safe_dir (dir);
+    sprintf (server.sun_path, "%s/esrv-%s", dir, system_name);
+  }
 
   if (unlink (server.sun_path) == -1 && errno != ENOENT)
     {
