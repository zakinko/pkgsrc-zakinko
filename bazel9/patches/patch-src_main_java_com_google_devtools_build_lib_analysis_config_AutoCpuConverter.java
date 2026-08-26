$NetBSD$

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
