$NetBSD$

Keep the added headers out of the Makefile-generating pass.

config.h is read twice: once by the compiler, and once by the cpp run that
turns Makefile.in into Makefile.  The second one is traditional cpp and
cannot read a modern glibc header at all, so the includes have to sit
inside #ifndef NOT_C_CODE, the way s/irix4-0.h does it.

--- src/syssignal.h.orig
+++ src/syssignal.h
@@ -33,6 +33,10 @@
 
 /* POSIX pretty much destroys any possibility of writing sigmask as a
    macro in standard C.  */
+/* glibc は <signal.h> で sigmask を巨視として定義する。あれは int を返すので、
+   sigset_t を取る sys_sigblock に渡すと型が合わない。#ifndef では避けられない
+   ので、POSIX の側を使うと決めたここで一度外す。 */
+#undef sigmask
 #ifndef sigmask
 #ifdef __GNUC__
 #define sigmask(SIG) 				\
