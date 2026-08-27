$NetBSD$

Name the auto-detected CPU consistently with the other BSDs.

This is what --cpu resolves to when it is not given.  FreeBSD and OpenBSD
each use their own name rather than a CPU name; do the same.

--- src/main/java/com/google/devtools/build/lib/analysis/config/AutoCpuConverter.java.orig
+++ src/main/java/com/google/devtools/build/lib/analysis/config/AutoCpuConverter.java
@@ -39,6 +39,7 @@
               default -> "unknown";
             };
         case FREEBSD -> "freebsd";
+        case NETBSD -> "netbsd";
         case OPENBSD -> "openbsd";
         case WINDOWS ->
             switch (CPU.getCurrent()) {
