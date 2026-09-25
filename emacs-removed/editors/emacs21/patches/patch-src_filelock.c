$NetBSD$

Do not include <utmp.h> where the system does not have it.

DragonFly replaced utmp with utmpx and removed <utmp.h>; 6.4 ships utmpx.h and
no utmp.h.  The include here sits outside any guard, so the build stops at

	filelock.c:68:10: fatal error: utmp.h: No such file or directory

Nothing in this file needs the header on such a system.  The one place that
names the type,

	struct utmp ut, *utp;			(get_boot_time_1)

is inside #ifdef BOOT_TIME, and the routines that call into libc's utmp
functions are inside

	#if defined (BOOT_TIME) && ! defined (NO_WTMP_FILE)

BOOT_TIME is not a configure result -- it is the ut_type constant that glibc's
<utmp.h> defines.  Where the header is absent it is undefined, so
get_boot_time_1 and its callers compile away and the include is the only thing
left.

editors/emacs20 carries the same patch; the two files differ only in where the
include sits.

--- src/filelock.c.orig
+++ src/filelock.c
@@ -65,7 +65,9 @@
 
 #ifdef CLASH_DETECTION
 
+#ifndef NO_UTMP_H
 #include <utmp.h>
+#endif
 
 /* A file whose last-modified time is just after the most recent boot.
    Define this to be NULL to disable checking for this file.  */
