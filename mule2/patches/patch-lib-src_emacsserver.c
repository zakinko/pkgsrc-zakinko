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

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

Pass and store pointers of the type the other side declares.

gcc 14 turned a pointer type mismatch into an error, so what used to be a
warning here now stops the build.  Where the declaration was simply wrong
it is corrected; where the system call or the library has moved since 1995
the value is converted at the call.

--- lib-src/emacsserver.c.orig
+++ lib-src/emacsserver.c
@@ -53,12 +53,43 @@
 #include <sys/socket.h>
 #include <sys/signal.h>
 #include <sys/un.h>
+#include <sys/stat.h>
 #include <stdio.h>
 #include <errno.h>
 #include <stdlib.h>
 #include <string.h>
 
-main ()
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
+
+int main ()
 {
   char system_name[32];
   int s, infd, fromlen;
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
@@ -137,7 +177,7 @@
 	  fromlen = sizeof (fromunix);
 	  fromunix.sun_family = AF_UNIX;
 	  infd = accept (s, (struct sockaddr *) &fromunix,
-			 (size_t *) &fromlen);
+			 (socklen_t *) &fromlen);
 	  if (infd < 0)
 	    {
 	      if (errno == EMFILE || errno == ENFILE)
