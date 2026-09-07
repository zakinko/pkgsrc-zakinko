$NetBSD$

Add NetBSD to the systems bazel knows.

OS.getCurrent() maps the JVM's os.name onto this enum, and everything that
switches on the operating system reads it.  Without an entry NetBSD is
UNKNOWN, which is not POSIX-compatible as far as the rest of the code is
concerned, and the client refuses to run.

--- src/main/java/com/google/devtools/build/lib/util/OS.java.orig	1980-01-01 00:00:00.000000000 +0000
+++ src/main/java/com/google/devtools/build/lib/util/OS.java
@@ -21,12 +21,14 @@ import java.util.EnumSet;
 public enum OS {
   DARWIN("osx", "Mac OS X"),
   FREEBSD("freebsd", "FreeBSD"),
+  NETBSD("netbsd", "NetBSD"),
+  DRAGONFLY("dragonfly", "DragonFly"),
   OPENBSD("openbsd", "OpenBSD"),
   LINUX("linux", "Linux"),
   WINDOWS("windows", "Windows"),
   UNKNOWN("unknown", "");
 
-  private static final EnumSet<OS> POSIX_COMPATIBLE = EnumSet.of(DARWIN, FREEBSD, OPENBSD, LINUX);
+  private static final EnumSet<OS> POSIX_COMPATIBLE = EnumSet.of(DARWIN, FREEBSD, NETBSD, DRAGONFLY, OPENBSD, LINUX);
 
   private final String canonicalName;
   private final String detectionName;
