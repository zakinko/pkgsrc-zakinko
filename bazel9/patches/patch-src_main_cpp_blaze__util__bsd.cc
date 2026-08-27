$NetBSD$

Make the BSD client source build on NetBSD.

Three things differ.  The JDK lives under a different prefix.  statfs(2)
was removed in NetBSD 10; statvfs(2) carries the f_fstypename this code
wants, so use it.  And there is no way for a process to learn the path to
its own executable that is available this early, which is the same
situation OpenBSD is in, so share that arm.

--- src/main/cpp/blaze_util_bsd.cc.orig
+++ src/main/cpp/blaze_util_bsd.cc
@@ -15,6 +15,8 @@
 #if defined(__FreeBSD__)
 # define HAVE_PROCSTAT
 # define STANDARD_JAVABASE "/usr/local/openjdk8"
+#elif defined(__NetBSD__)
+# define STANDARD_JAVABASE "@PKG_JAVA_HOME@"
 #elif defined(__OpenBSD__)
 # define STANDARD_JAVABASE "/usr/local/jdk-17"
 #else
@@ -81,8 +83,14 @@
 }
 
 void WarnFilesystemType(const blaze_util::Path &output_base) {
+#if defined(__NetBSD__)
+  // NetBSD dropped statfs(2); statvfs(2) carries f_fstypename all the same.
+  struct statvfs buf = {};
+  if (statvfs(output_base.AsNativePath().c_str(), &buf) < 0) {
+#else
   struct statfs buf = {};
   if (statfs(output_base.AsNativePath().c_str(), &buf) < 0) {
+#endif
     BAZEL_LOG(WARNING) << "couldn't get file system type information for '"
                        << output_base.AsPrintablePath()
                        << "': " << strerror(errno);
@@ -119,7 +127,7 @@
   }
   procstat_close(procstat);
   return string(buffer);
-#elif defined(__OpenBSD__)
+#elif defined(__OpenBSD__) || defined(__NetBSD__)
   // OpenBSD does not provide a way for a running process to find a path to its
   // own executable, so we try to figure out a path by inspecting argv[0]. In
   // theory this is inadequate, since the parent process can set argv[0] to
