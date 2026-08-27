$NetBSD$

echoptr must not start as a null pointer.  With -batch nothing runs the
command loop, so cancel_echoing() never sets it; a y-or-n-p asked from C
-- Wnn asking whether to create the user dictionary -- then reaches
echo_dash() with echoptr == 0 and writes through it.  Only the batch
path is affected: interactively the command loop sets echoptr first.

--- src/keyboard.c.orig	2026-06-21 15:38:42.000000000 +0000
+++ src/keyboard.c
@@ -327,7 +327,11 @@
 #define	max(a,b)	((a)>(b)?(a):(b))
 
 static char echobuf[100];
-static char *echoptr;
+/* Must not start as a null pointer.  With -batch nothing runs the
+   command loop, so cancel_echoing() never sets it, and a y-or-n-p asked
+   from C -- Wnn asking whether to create the user dictionary -- reaches
+   echo_dash() with echoptr == 0 and writes through it.  */
+static char *echoptr = echobuf;
 
 /* Install the string STR as the beginning of the string of echoing,
    so that it serves as a prompt for the next character.
