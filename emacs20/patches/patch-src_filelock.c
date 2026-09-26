$NetBSD$

Do not include <utmp.h> where the system does not have it.

FreeBSD replaced utmp with utmpx and removed <utmp.h>; DragonFly did the same.
Neither 14.4 nor 6.4.2 ships the header, so the build stops at

	filelock.c:67:10: fatal error: 'utmp.h' file not found

Nothing in this file actually needs the header on those systems.  Every use of
utmp sits inside

	#if defined (BOOT_TIME) && ! defined (NO_WTMP_FILE)

and BOOT_TIME is not a configure result -- it is the ut_type constant that
glibc's <utmp.h> defines.  Where the header is absent, or present but of the
older BSD kind without ut_type, BOOT_TIME is undefined and get_boot_time_1 and
its callers compile away.  So the include is the only thing left, and dropping
it changes nothing beyond letting the file compile.

NO_UTMP_H is spelled the way this tree spells its other system quirks --
NO_TERMIO, NO_SIOCTL_H -- and is set from the s/ file, which is where emacs 20
keeps them.

--- src/filelock.c.orig	2000-04-19 21:03:44.000000000 +0000
+++ src/filelock.c
@@ -64,7 +64,9 @@ Lisp_Object Vtemporary_file_directory;
 
 #ifdef CLASH_DETECTION
 
+#ifndef NO_UTMP_H
 #include <utmp.h>
+#endif
 
 /* A file whose last-modified time is just after the most recent boot.
    Define this to be NULL to disable checking for this file.  */
