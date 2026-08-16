$NetBSD$

An operating system description for DragonFly, which is close enough to
4.3BSD for this tree given that it has getloadavg.

Not from upstream: no src/s/dragonfly.h exists in any Emacs release
checked.  DragonFly appeared after this tree stopped being maintained.

The file was copied from s/freebsd.h, and with it the ladder that defines
BSD only for __FreeBSD__ 1 and 2.  DragonFly does not define __FreeBSD__ at
all, so BSD stayed undefined after the #undef and the tree took its non-BSD
paths, which does not build; see patch-src_s_freebsd.h for what breaks.
DragonFly is 4.4BSD-Lite2 derived, so it gets the same 199506 that Emacs
21.1 gives FreeBSD 3 and newer.

--- /dev/null	2006-01-04 20:13:24.000000000 +0000
+++ src/s/dragonfly.h
@@ -0,0 +1,64 @@
+/* Get most of the stuff from bsd4.3 */
+#include "bsd4-3.h"
+
+/* For mem-limits.h. */
+#define BSD4_2
+
+/* thses aren't needed, since we have getloadavg() */
+#undef KERNEL_FILE
+#undef LDAV_SYMBOL
+
+#define PENDING_OUTPUT_COUNT(FILE) (__fpending(FILE))
+
+#define LIBS_DEBUG
+#define LIBS_SYSTEM -lutil -lcrypt
+#define LIBS_TERMCAP -ltermcap
+#define LIB_GCC -lgcc
+
+/* Reread the time zone on startup. */
+#define LOCALTIME_CACHE
+
+#define SYSV_SYSTEM_DIR
+
+/* freebsd has POSIX-style pgrp behavior. */
+#undef BSD_PGRPS
+
+#define LD_SWITCH_SYSTEM -e _start
+#define HAVE_TEXT_START		/* No need to define `start_of_text'. */
+#define UNEXEC unexelf.o
+
+#ifndef N_TRELOFF
+#define N_PAGSIZ(x) __LDPGSZ
+#define N_BSSADDR(x) (N_ALIGN(x, N_DATADDR(x)+x.a_data))
+#define N_TRELOFF(x) N_RELOFF(x)
+#endif
+
+#define HAVE_WAIT_HEADER
+#define HAVE_GETLOADAVG
+#define HAVE_TERMIOS
+#define NO_TERMIO
+#define DECLARE_GETPWUID_WITH_UID_T
+
+/* freebsd uses OXTABS instead of the expected TAB3. */
+#define TABDLY OXTABS
+#define TAB3 OXTABS
+
+/* DragonFly does not define __FreeBSD__, so the version ladder this file
+   was copied with left BSD undefined.  It is 4.4BSD-Lite2 derived. */
+#undef BSD
+#define BSD 199506
+
+#define WAITTYPE int
+/* get this since it won't be included if WAITTYPE is defined */
+#ifdef emacs
+#include <sys/wait.h>
+#endif
+#define WRETCODE(w) (_W_INT(w) >> 8)
+#define CURRENT_USER
+#define NO_MATHERR
+
+#define ORDINARY_LINK
+
+#if defined(__i386__)
+#define DATA_SEG_BITS 0x08000000
+#endif /* __i386__ */
