$NetBSD$

--- src/main/java/com/google/devtools/build/lib/bazel/rules/BazelRuleClassProvider.java.orig
+++ src/main/java/com/google/devtools/build/lib/bazel/rules/BazelRuleClassProvider.java
@@ -94,6 +94,7 @@
       ImmutableMap.<OS, PathFragment>builder()
           .put(OS.WINDOWS, PathFragment.create("c:/msys64/usr/bin/bash.exe"))
           .put(OS.FREEBSD, PathFragment.create("/usr/local/bin/bash"))
+          .put(OS.NETBSD, PathFragment.create("/usr/pkg/bin/bash"))
           .put(OS.OPENBSD, PathFragment.create("/usr/local/bin/bash"))
           .put(OS.LINUX, PathFragment.create("/bin/bash"))
           .put(OS.DARWIN, PathFragment.create("/bin/bash"))
