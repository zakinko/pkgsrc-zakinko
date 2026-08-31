$NetBSD$

Item 6: emacsclient computed the same predictable socket name
/tmp/esrv<uid>-<host> that emacsserver bound (see patch-item6-emacsserver),
and although it checked the socket file was owned by us, it did not check the
directory -- so a filename could be handed to a listener in a directory an
attacker controlled.  Follow emacsserver: build the path under the per-user
directory and refuse to use it unless that directory is a real directory
owned by us with no group or other permission bits.  The client does not
create the directory; a missing one just means the server is not running.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

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

Fix what only the Linux arm of this file compiles.

These lines are inside #ifdef arms that NetBSD does not take, so nothing
here shows up when the package is built there.  glibc reaches them.

--- lib-src/emacsclient.c.orig
+++ lib-src/emacsclient.c
@@ -19,7 +19,23 @@
 
 
 #define NO_SHORTNAMES
+
+/* glibc は struct msgbuf を _GNU_SOURCE の側へ移した。__USE_MISC が立って
+   いても、_DEFAULT_SOURCE や _XOPEN_SOURCE=700 では出てこない (Fedora 44 で
+   確かめた)。この file は SysV IPC の枝でだけそれを使うので、ここで頼む。
+   最初のヘッダより前でないと効かない。__GLIBC__ で囲ってはいけない。
+   あれが定義されるのは glibc のヘッダを一枚読んだ後で、ここではまだ偽。  */
+#ifndef _GNU_SOURCE
+#define _GNU_SOURCE 1
+#endif
+
 #include <../src/config.h>
+
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+#include <unistd.h>
+#include <string.h>
+#include <fcntl.h>
 #undef read
 #undef write
 #undef open
@@ -30,7 +46,7 @@
 #if !defined(HAVE_SOCKETS) && !defined(HAVE_SYSVIPC)
 #include <stdio.h>
 
-main (argc, argv)
+int main (argc, argv)
      int argc;
      char **argv;
 {
@@ -54,7 +70,7 @@
 
 extern char *strerror ();
 
-main (argc, argv)
+int main (argc, argv)
      int argc;
      char **argv;
 {
@@ -85,9 +101,32 @@
 #ifndef SERVER_HOME_DIR
   {
     struct stat statbfr;
+    char *tmpdir = getenv ("TMPDIR");
+    char dir[1024];
 
+    if (tmpdir == 0 || *tmpdir == 0)
+      tmpdir = "/tmp";
     gethostname (system_name, sizeof (system_name));
-    sprintf (server.sun_path, "/tmp/esrv%d-%s", geteuid (), system_name);
+    sprintf (dir, "%s/emacs%d", tmpdir, (int) geteuid ());
+
+    /* The socket lives in a per-user directory now (see emacsserver.c);
+       refuse to trust anything inside it, or send a file name to whatever is
+       listening there, unless the directory is really ours and private.  */
+    if (lstat (dir, &statbfr) == -1)
+      {
+	if (errno == ENOENT)
+	  fprintf (stderr, "Can't find socket; have you started the server?\n");
+	else
+	  perror ("lstat");
+	exit (1);
+      }
+    if (!S_ISDIR (statbfr.st_mode) || statbfr.st_uid != geteuid ()
+	|| (statbfr.st_mode & 077) != 0)
+      {
+	fprintf (stderr, "The socket directory %s is unsafe\n", dir);
+	exit (1);
+      }
+    sprintf (server.sun_path, "%s/esrv-%s", dir, system_name);
 
     if (stat (server.sun_path, &statbfr) == -1)
       {
@@ -175,7 +214,7 @@
 
 char *getwd (), *getcwd (), *getenv ();
 
-main (argc, argv)
+int main (argc, argv)
      int argc;
      char **argv;
 {
