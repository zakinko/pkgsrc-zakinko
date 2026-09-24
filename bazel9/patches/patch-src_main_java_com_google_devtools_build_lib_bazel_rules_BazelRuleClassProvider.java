$NetBSD$

Run genrules under /bin/sh.

This is the shell a genrule cmd runs under when neither --shell_executable
nor BAZEL_SH says otherwise.  Upstream names a bash for every entry, and
on the BSDs that is a path outside the base system: /usr/local/bin/bash on
FreeBSD and OpenBSD, and on NetBSD and DragonFly no bash at all unless one
is installed.  So bazel could not run a genrule on a machine that had only
bazel on it.

Every one of these systems has /bin/sh, and a genrule cmd is a shell
command rather than a bash script.  Moving the fallback to /bin/sh and
dropping the entries that only repeated a bash covers all of them at once,
including the two upstream does not list -- getOrDefault reaches the
fallback for those, so neither NetBSD nor DragonFly needs naming here.

Windows keeps its bash.exe; there is no /bin/sh to name there.

This does change what a genrule cmd may contain: one written in bash
syntax will now fail where it used to work.  BAZEL_SH still overrides the
default, so installing a bash and pointing BAZEL_SH at it restores the
old behaviour.

--- src/main/java/com/google/devtools/build/lib/bazel/rules/BazelRuleClassProvider.java.orig
+++ src/main/java/com/google/devtools/build/lib/bazel/rules/BazelRuleClassProvider.java
@@ -87,16 +87,12 @@
     public boolean useStrictActionEnv;
   }
 
-  private static final PathFragment FALLBACK_SHELL = PathFragment.create("/bin/bash");
+  private static final PathFragment FALLBACK_SHELL = PathFragment.create("/bin/sh");
 
   @VisibleForTesting
   public static final ImmutableMap<OS, PathFragment> SHELL_EXECUTABLES =
       ImmutableMap.<OS, PathFragment>builder()
           .put(OS.WINDOWS, PathFragment.create("c:/msys64/usr/bin/bash.exe"))
-          .put(OS.FREEBSD, PathFragment.create("/usr/local/bin/bash"))
-          .put(OS.OPENBSD, PathFragment.create("/usr/local/bin/bash"))
-          .put(OS.LINUX, PathFragment.create("/bin/bash"))
-          .put(OS.DARWIN, PathFragment.create("/bin/bash"))
           .put(OS.UNKNOWN, FALLBACK_SHELL)
           .buildOrThrow();
 
