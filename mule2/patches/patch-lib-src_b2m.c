$NetBSD$

Stop using gets(3).

C11 removed it and the C libraries this is built against no longer define it,
so the link of b2m fails outright on FreeBSD.  The comment at the top of the
file has been asking for this since 1988, and this is the only file compiled
here that still calls it.

b2m_gets is bounded by the size of the buffer, which is where the crash the
comment warns about came from, and otherwise behaves as gets did: the newline
is dropped, so the strcmp against "*** EOOH ***" and "\037\f" still match,
and NULL comes back at end of file.

While here, include <string.h> and <stdlib.h>.  strcmp, strcpy, strcat,
strlen and exit were all being called without a declaration.  The hand-written
extern for strtok goes with them -- it was there because BSD's strings.h did
not give the return type, and with string.h included it now disagrees with
the real prototype.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- lib-src/b2m.c.orig
+++ lib-src/b2m.c
@@ -15,10 +15,13 @@
  *   Mon Nov 7 15:54:06 PDT 1988
  */
 
-/* Serious bug: This program uses `gets', which is intrinsically
-   unreliable--long lines will cause crashes.
-   Someone should fix this program not to use `gets'.  */
+/* This program used `gets', which is intrinsically unreliable -- long lines
+   will cause crashes -- and which C11 removed and the C libraries this is
+   built against no longer provide.  b2m_gets below reads a line the way gets
+   did, without running off the end of the buffer.  */
 #include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
 #include <time.h>
 #include <sys/types.h>
 #ifdef MSDOS
@@ -27,9 +30,6 @@
 
 #include <../src/config.h>
 
-/* BSD's strings.h does not declare the type of strtok.  */
-extern char *strtok ();
-
 #ifndef TRUE
 #define TRUE  (1)
 #endif
@@ -41,7 +41,24 @@
 time_t ltoday;
 char from[256], labels[256], data[256], *p, *today;
 
-main (argc, argv)
+/* Read one line into BUF, at most SIZE bytes including the terminator.
+   Like gets, the newline is dropped and NULL comes back at end of file.  */
+static char *
+b2m_gets (buf, size)
+     char *buf;
+     int size;
+{
+  size_t len;
+
+  if (fgets (buf, size, stdin) == NULL)
+    return NULL;
+  len = strlen (buf);
+  if (len > 0 && buf[len - 1] == '\n')
+    buf[len - 1] = '\0';
+  return buf;
+}
+
+int main (argc, argv)
      int argc;
      char **argv;
 {
@@ -58,8 +75,7 @@
   ltoday = time (0);
   today = ctime (&ltoday);
 
-  /* BUG!  Must not use gets in a reliable program!  */
-  if (gets (data))
+  if (b2m_gets (data, sizeof data))
     {
       if (strncmp (data, "BABYL OPTIONS:", 14))
 	{
@@ -74,7 +90,7 @@
   if (printing)
     puts (data);
 
-  while (gets (data))
+  while (b2m_gets (data, sizeof data))
     {
 
 #if 0
@@ -94,7 +110,7 @@
       if (!strcmp (data, "\037\f"))
 	{
 	  /* save labels */
-	  gets (data);
+	  b2m_gets (data, sizeof data);
 	  p = strtok (data, " ,\r\n\t");
 	  strcpy (labels, "X-Babyl-Labels: ");
 
