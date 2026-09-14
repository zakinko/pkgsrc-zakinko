$NetBSD$

Add NetBSD and DragonFly to the list that gets a POSIX write(2).

The list names the platforms where ABSL_HAVE_POSIX_WRITE and
ABSL_LOW_LEVEL_WRITE_SUPPORTED are set, and neither NetBSD nor DragonFly
is on it.  Both have write(2) in <unistd.h>.

Without them the failure is silent: the file still compiles, the program
still runs, and every ABSL_RAW_LOG goes nowhere, because the fallback
path has nothing to write with.  Nothing points at the missing output.

Submitted upstream as abseil/abseil-cpp#2160.  Written out for the
abseil mozc pins, where the list is wrapped across different lines.

--- third_party/abseil-cpp/absl/base/internal/raw_logging.cc.orig
+++ third_party/abseil-cpp/absl/base/internal/raw_logging.cc
@@ -44,6 +44,7 @@
 #if defined(__linux__) || defined(__APPLE__) || defined(__FreeBSD__) || \
     defined(__hexagon__) || defined(__Fuchsia__) ||                     \
     defined(__native_client__) || defined(__OpenBSD__) ||               \
+    defined(__NetBSD__) || defined(__DragonFly__) ||                    \
     defined(__EMSCRIPTEN__) || defined(__ASYLO__)
 
 #include <unistd.h>
