$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

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
