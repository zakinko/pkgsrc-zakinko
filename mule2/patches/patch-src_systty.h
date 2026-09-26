$NetBSD$

Include <sys/ioctl.h> for the ioctl in EMACS_OUTQSIZE.

The macro is expanded in whatever file includes this header, so the
declaration has to travel with the macro.

--- src/systty.h.orig
+++ src/systty.h
@@ -17,6 +17,9 @@
 along with GNU Emacs; see the file COPYING.  If not, write to
 the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.  */
 
+
+/* EMACS_OUTQSIZE が ioctl を呼ぶ。宣言はここで入れる。  */
+#include <sys/ioctl.h>
 #ifdef HAVE_TERMIOS
 #define HAVE_TCATTR
 #endif
