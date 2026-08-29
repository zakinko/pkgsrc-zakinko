$NetBSD: patch-ai,v 1.3 2012/12/11 04:54:43 dholland Exp $

On NetBSD ELF the linker provides the start-of-text symbol, so emacs's own
guess is both unnecessary and wrong.  HAVE_TEXT_START is not set by configure
here, so the fallback would otherwise be compiled in.

--- src/sysdep.c.orig	2000-05-24 13:59:14.000000000 +0000
+++ src/sysdep.c
@@ -2134,6 +2132,7 @@ unrequest_sigio ()
  *
  */
 
+#if !(defined (__NetBSD__) && defined (__ELF__))
 #ifndef HAVE_TEXT_START
 char *
 start_of_text ()
@@ -2151,6 +2150,7 @@ start_of_text ()
 #endif /* TEXT_START */
 }
 #endif /* not HAVE_TEXT_START */
+#endif
 
 /*
  *	Return the address of the start of the data segment prior to
