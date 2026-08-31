$NetBSD$

Declare what this program calls, so nothing is reached through an implicit
declaration -- the form C99 removed and clang 16 and gcc 14 reject.  The
standard functions come through their headers, with the file's own
hand-written declarations of them removed where they disagreed; the tree's
own come through the type their definition carries.

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

Undo the interruptible-system-call remapping before any header is read.

s/linux.h defines read, write, open and close as the sys_* wrappers that
sysdep.c provides for the Emacs binary.  lib-src does not link against
sysdep.c, and with the macros in force <fcntl.h> declares sys_open rather
than open, so the call site is left with no declaration at all.  On Fedora
44 that is an error and the build stops in movemail.

emacsclient.c and emacsserver.c already undo it at the top; movemail.c and
timer.c never did.  NetBSD does not remap, so nothing changes there.

--- lib-src/movemail.c.orig
+++ lib-src/movemail.c
@@ -50,6 +50,17 @@
 
 #define NO_SHORTNAMES   /* Tell config not to load remap.h */
 #include <../src/config.h>
+
+/* s/linux.h は割り込まれ得る system call を、sysdep.c が持つ再試行つきの
+   sys_* に差し替える。あれは Emacs 本体のための仕掛けで、lib-src の道具は
+   sysdep.c と繋がらない。差し替えたままヘッダを読むと <fcntl.h> が宣言する
+   のは open ではなく sys_open になり、呼ぶ側には宣言も実体も無くなる。
+   最初のヘッダより前で戻す。emacsclient.c と emacsserver.c は元から同じ事を
+   している。  */
+#undef read
+#undef write
+#undef open
+#undef close
 #include <sys/types.h>
 #include <sys/stat.h>
 #include <sys/file.h>
@@ -59,6 +70,22 @@
 #include <string.h>
 #include <../src/syswait.h>
 
+/* Declare the standard functions this file calls. */
+#include <time.h>
+
+/* Declare the standard functions this file calls. */
+#include <unistd.h>
+#include <fcntl.h>
+#include <sys/wait.h>
+
+/* Declare what this program calls: the standard functions through their
+   headers, the tree's own through the type their definition carries.
+   Reaching either through an implicit declaration is what C99 removed. */
+extern int error ();
+extern int fatal ();
+extern int pfatal_and_delete ();
+extern int pfatal_with_name ();
+
 #ifdef MSDOS
 #undef access
 #endif /* MSDOS */
@@ -109,7 +136,7 @@
 /* Nonzero means this is name of a lock file to delete on fatal error.  */
 char *delete_lockname;
 
-main (argc, argv)
+int main (argc, argv)
      int argc;
      char **argv;
 {
@@ -337,7 +364,7 @@
       exit (0);
     }
 
-  wait (&status);
+  wait ((int *) &status);
   if (!WIFEXITED (status))
     exit (1);
   else if (WRETCODE (status) != 0)
@@ -351,7 +378,7 @@
 
 /* Print error message and exit.  */
 
-fatal (s1, s2)
+int fatal (s1, s2)
      char *s1, *s2;
 {
   if (delete_lockname)
@@ -362,7 +389,7 @@
 
 /* Print error message.  `s1' is printf control string, `s2' is arg for it. */
 
-error (s1, s2, s3)
+int error (s1, s2, s3)
      char *s1, *s2, *s3;
 {
   printf ("movemail: ");
@@ -370,7 +397,7 @@
   printf ("\n");
 }
 
-pfatal_with_name (name)
+int pfatal_with_name (name)
      char *name;
 {
   extern char *strerror ();
@@ -380,7 +407,7 @@
   fatal (s, name);
 }
 
-pfatal_and_delete (name)
+int pfatal_and_delete (name)
      char *name;
 {
   extern char *strerror ();
