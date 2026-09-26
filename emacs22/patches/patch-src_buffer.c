$NetBSD$

Drop the hand-written

	#ifndef USE_CRT_DLL
	extern int errno;
	#endif

Upstream removed all eleven of these -- ten in src, one in lib-src -- between
23.4 and 24.1, and 24.1 is where src/m and the rest of the pre-C89 scaffolding
went too.

Be exact about what it does today, because editors/emacs21 says something
stronger and it does not hold.  On NetBSD 11 <errno.h> has

	#define errno (*__errno())

so the declaration above is not a declaration of errno at all: the macro
rewrites it first, and what the compiler sees is a K&R declaration of the
accessor, "extern int (*__errno());".  That still compiles and links with
gcc 12.5, and errno set through the macro reads back correctly -- measured
with a three-line program.  So this is not what stops a build.  What it does
do is leave a declaration that means nothing and that -Wstrict-prototypes
reports:

	warning: function declaration isn't a prototype [-Wstrict-prototypes]

Removing it is upstream's own answer, one release later.

--- src/buffer.c.orig	2008-10-10 10:35:49.000000000 +0900
+++ src/buffer.c
@@ -29,11 +29,6 @@ Boston, MA 02110-1301, USA.  */
 #include <errno.h>
 #include <stdio.h>
 
-#ifndef USE_CRT_DLL
-extern int errno;
-#endif
-
-
 #ifdef HAVE_UNISTD_H
 #include <unistd.h>
 #endif
