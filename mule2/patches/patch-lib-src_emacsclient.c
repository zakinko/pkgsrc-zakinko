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

--- lib-src/emacsclient.c.orig
+++ lib-src/emacsclient.c
@@ -20,6 +20,12 @@
 
 #define NO_SHORTNAMES
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
@@ -54,7 +60,7 @@
 
 extern char *strerror ();
 
-main (argc, argv)
+int main (argc, argv)
      int argc;
      char **argv;
 {
@@ -85,9 +91,32 @@
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
