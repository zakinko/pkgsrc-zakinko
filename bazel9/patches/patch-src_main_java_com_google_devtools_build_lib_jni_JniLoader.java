$NetBSD$

Load the JNI library built for this system.

The Unix arm covers Linux, FreeBSD and OpenBSD and is right for NetBSD as
well; the file being loaded is the one src/main/native/BUILD just built.

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
