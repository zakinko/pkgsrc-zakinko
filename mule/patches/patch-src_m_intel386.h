$NetBSD$

call0 through call6 and apply1 take the address of their first parameter and
hand it to Ffuncall as an array of all of them, on the assumption that the
arguments sit next to each other in memory.  That holds while the function
has a real frame.  It stops holding the moment the compiler inlines it: the
parameters become values with no layout at all, &fn addresses one slot, and
everything past the first is whatever happened to be on the stack.

GCC 12 inlines call4 into do_autoload, so the file name meant for load(1)
arrives as a stack address, substitute-in-file-name is handed a non-string,
and nothing that autoloads works.  byte-compile is the visible casualty
because byte-optimize-lapcode is autoloaded.  GCC 7.5 did not inline it,
which is why this only shows up on newer compilers.

NO_ARG_ARRAY is the switch the tree already provides for machines where the
assumption does not hold, and it makes those functions build an explicit
array instead.  Every other machine description we build for -- amd64,
sparc, alpha, powerpc -- defines it.  i386 is the one that left it
commented out.

--- src/m/intel386.h.orig	1994-05-04 06:37:41.000000000 +0000
+++ src/m/intel386.h
@@ -70,7 +70,7 @@
 /* Define NO_ARG_ARRAY if you cannot take the address of the first of a
  * group of arguments and treat it as an array of the arguments.  */
 
-/* #define NO_ARG_ARRAY */
+#define NO_ARG_ARRAY
 
 /* Define WORD_MACHINE if addresses and such have
  * to be corrected before they can be used as byte counts.  */
