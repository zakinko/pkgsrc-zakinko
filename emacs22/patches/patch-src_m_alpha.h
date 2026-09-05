$NetBSD$

Do not force DATA_START on NetBSD/alpha.  The value 0x140000000 is the Tru64
layout, and the #ifndef LINUX around it says only that GNU/Linux is different;
NetBSD is different in the same way, so it is excluded too.

This one is not upstream's.  23.1 still has the plain "#ifndef GNU_LINUX"
here, and 24.1 removed src/m altogether rather than fixing the individual
files, so there is no later version of this change to take.

--- src/m/alpha.h.orig	2008-01-08 13:04:36.000000000 +0900
+++ src/m/alpha.h
@@ -106,7 +106,7 @@ NOTE-END
 #ifdef __ELF__
 #undef UNEXEC
 #define UNEXEC unexelf.o
-#ifndef LINUX
+#if !defined(LINUX) && !defined(__NetBSD__)
 #define DATA_START    0x140000000
 #endif
 #endif
