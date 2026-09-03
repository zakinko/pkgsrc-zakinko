$NetBSD$

Add a BSD block to the GYP defaults, keyed on target_platform.

Without it protoc fails to link with an undefined reference to
pthread_getschedparam, because ldflags carries no -pthread.  Measured on
FreeBSD 14.3: the same symbol, the same reason.  NetBSD hides it less
often because more of pthread lives in libc there.

The condition is on target_platform rather than OS.  gyp derives OS from
GetFlavor() in third_party/gyp/pylib/gyp/common.py, which knows freebsd,
openbsd, netbsd, sunos, aix and zos and returns 'linux' for anything else.
Measured:

  FreeBSD 15    sys.platform freebsd15   flavor freebsd
  OpenBSD 7     sys.platform openbsd7    flavor openbsd
  DragonFly 6   sys.platform dragonfly6  flavor linux
  GhostBSD      sys.platform freebsd15   flavor freebsd

So OS=="dragonfly" never matches, and DragonFly would fall into the linux
arm with no -pthread.  target_platform is mozc's own value and is right on
all four.  GhostBSD needs nothing extra: it reports itself as FreeBSD.

--- gyp/common.gypi.orig
+++ gyp/common.gypi
@@ -74,6 +74,14 @@
       '-fstack-protector',
       '--param=ssp-buffer-size=4',
     ],
+    # netbsd_cflags will be used for NetBSD.
+    'netbsd_cflags': [
+      '<@(gcc_cflags)',
+      '-fPIC',
+      '-D_NETBSD_SOURCE',
+      '-fno-exceptions',
+      '<!(echo $CFLAGS)',
+    ],
     # mac_cflags will be used in Mac.
     # Xcode 4.5 which we are currently using does not support ssp-buffer-size.
     # TODO(horo): When we can use Xcode 4.6 which supports ssp-buffer-size,
@@ -103,6 +111,12 @@
         'compiler_target': 'gcc',
         'compiler_host': 'gcc',
       }],
+      ['target_platform=="NetBSD" or target_platform=="FreeBSD" or target_platform=="OpenBSD" or target_platform=="DragonFly"', {
+        'compiler_target': 'gcc',
+        'compiler_target_version_int': 409,  # GCC 4.9 or higher
+        'compiler_host': 'gcc',
+        'compiler_host_version_int': 409,  # GCC 4.9 or higher
+      }],
     ],
   },
   'target_defaults': {
@@ -222,6 +236,24 @@
           '-Wno-deprecated',
         ],
       }],
+      ['target_platform=="NetBSD" or target_platform=="FreeBSD" or target_platform=="OpenBSD" or target_platform=="DragonFly"', {
+        'defines': [
+          'OS_NETBSD',
+        ],
+        'cflags': [
+          '<@(netbsd_cflags)',
+          '-fPIC',
+          '-fno-exceptions',
+        ],
+        'cflags_cc': [
+          # We use deprecated <hash_map> and <hash_set> instead of upcoming
+          # <unordered_map> and <unordered_set>.
+          '-Wno-deprecated',
+        ],
+        'ldflags': [
+          '-pthread',
+        ],
+      }],
       ['OS=="mac"', {
         'make_global_settings': [
           ['CC', '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang'],
