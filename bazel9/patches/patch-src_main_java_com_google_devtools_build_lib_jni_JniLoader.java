$NetBSD$

--- src/main/java/com/google/devtools/build/lib/jni/JniLoader.java.orig
+++ src/main/java/com/google/devtools/build/lib/jni/JniLoader.java
@@ -39,6 +39,7 @@
       switch (OS.getCurrent()) {
         case LINUX:
         case FREEBSD:
+        case NETBSD:
         case OPENBSD:
         case UNKNOWN:
           loadLibrary("main/native/libunix_jni.so");
