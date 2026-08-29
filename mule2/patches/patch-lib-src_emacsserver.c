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

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

Fix what only the Linux arm of this file compiles.

These lines are inside #ifdef arms that NetBSD does not take, so nothing
here shows up when the package is built there.  glibc reaches them.

Ask glibc for struct msgbuf the way it now wants to be asked.

glibc has moved the convenience struct that msgsnd and msgrcv take from
__USE_MISC to __USE_GNU.  On Fedora 44 neither _DEFAULT_SOURCE nor
_XOPEN_SOURCE=700 brings it back; only _GNU_SOURCE does.  It has to be
defined before the first header is read, so it goes at the top.

--- lib-src/emacsserver.c.orig
+++ lib-src/emacsserver.c
@@ -25,7 +25,24 @@
    up to the Emacs which then executes them.  */
 
 #define NO_SHORTNAMES
+
+/* glibc は struct msgbuf を _GNU_SOURCE の側へ移した。__USE_MISC が立って
+   いても、_DEFAULT_SOURCE や _XOPEN_SOURCE=700 では出てこない (Fedora 44 で
+   確かめた)。この file は SysV IPC の枝でだけそれを使うので、ここで頼む。
+   他の宣言まで変えないよう、s/linux.h ではなくこの file に置く。  */
+#ifdef __GLIBC__
+#define _GNU_SOURCE 1
+#endif
+
 #include <../src/config.h>
+
+/* Declare the standard functions this file calls. */
+#include <unistd.h>
+#include <fcntl.h>
+
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+#include <string.h>
 #undef read
 #undef write
 #undef open
@@ -36,7 +53,7 @@
 #if !defined(HAVE_SOCKETS) && !defined(HAVE_SYSVIPC)
 #include <stdio.h>
 
-main ()
+int main ()
 {
   fprintf (stderr, "Sorry, the Emacs server is supported only on systems\n");
   fprintf (stderr, "with Berkeley sockets or System V IPC.\n");
@@ -53,12 +70,43 @@
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
@@ -89,8 +137,17 @@
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
@@ -137,7 +194,7 @@
 	  fromlen = sizeof (fromunix);
 	  fromunix.sun_family = AF_UNIX;
 	  infd = accept (s, (struct sockaddr *) &fromunix,
-			 (size_t *) &fromlen);
+			 (socklen_t *) &fromlen);
 	  if (infd < 0)
 	    {
 	      if (errno == EMFILE || errno == ENFILE)
@@ -243,7 +300,7 @@
    Its stderr always exists--rms.  */
 #include <stdio.h>
 
-main ()
+int main ()
 {
   int s, infd, fromlen, ioproc;
   key_t key;
