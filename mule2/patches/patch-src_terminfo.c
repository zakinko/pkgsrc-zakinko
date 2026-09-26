$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/terminfo.c.orig
+++ src/terminfo.c
@@ -17,6 +17,10 @@
 along with GNU Emacs; see the file COPYING.  If not, write to
 the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.  */
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+#include <string.h>
+
 /* Define these variables that serve as global parameters to termcap,
    so that we do not need to conditionalize the places in Emacs
    that set them.  */
@@ -24,7 +28,7 @@
 char *UP, *BC, PC;
 short ospeed;
 
-static buffer[512];
+static int buffer[512];
 
 /* Interface to curses/terminfo library.
    Turns out that all of the terminfo-level routines look
@@ -38,6 +42,7 @@
      char *string;
      char *outstring;
      int arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9;
+     int len;
 {
   char *temp;
   extern char *tparm();
