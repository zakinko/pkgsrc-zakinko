$NetBSD$

execinfo.h is included unconditionally, but configure only ever looks for
the backtrace() library:

  configure.ac:204  AC_SEARCH_LIBS([backtrace], [execinfo], ...)

Nothing defines or tests HAVE_EXECINFO_H, so a system with the library but
no header -- or with neither -- stops at the include:

  we_unix.c:26:10: fatal error: 'execinfo.h' file not found

__has_include keeps the test in the source, so configure does not have to be
regenerated.  The crash handler simply writes no backtrace where the
facility is missing.

--- we_unix.c.orig
+++ we_unix.c
@@ -23,7 +23,23 @@
 #include <sys/wait.h>
 #include <dirent.h>
 #include <signal.h>
+/*
+ * configure looks for the backtrace() *library* (AC_SEARCH_LIBS) but never
+ * for the header, and nothing defines or tests HAVE_EXECINFO_H, so this
+ * include is unconditional.  On a system without execinfo.h the build stops
+ * here.  __has_include keeps the test in the source, where it does not need
+ * configure to be regenerated.
+ */
+#if defined(__has_include)
+# if __has_include(<execinfo.h>)
+#  define WPE_HAVE_EXECINFO 1
+# endif
+#elif defined(__GLIBC__)
+# define WPE_HAVE_EXECINFO 1
+#endif
+#ifdef WPE_HAVE_EXECINFO
 #include <execinfo.h>
+#endif
 #include <fcntl.h>
 #include <unistd.h>
 #include <locale.h>
@@ -437,8 +453,12 @@
 
   len = snprintf(line, sizeof(line), "CRASH: signal %d\n", sig);
   write(fd, line, len);
+#ifdef WPE_HAVE_EXECINFO
   n = backtrace(bt, 32);
   backtrace_symbols_fd(bt, n, fd);
+#else
+  (void)bt; (void)n;
+#endif
   len = snprintf(line, sizeof(line), "MAXSLNS=%d MAXSCOL=%d\n", MAXSLNS, MAXSCOL);
   write(fd, line, len);
   close(fd);
