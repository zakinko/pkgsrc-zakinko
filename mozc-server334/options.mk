# $NetBSD$

PKG_OPTIONS_VAR=	PKG_OPTIONS.mozc
PKG_SUPPORTED_OPTIONS=	gyp

.include "../../mk/bsd.prefs.mk"

# 3.34.6239 ships no GYP: no src/build_mozc.py, no src/gyp/, not one .gyp file.
# Bazel is the only way upstream builds it.  GYP went away in 3.33.6133, not in
# 3.34, so 3.33.6089 is the last tag that still has it, and the gyp option
# brings that scaffolding across from the 3.33.6089 tarball (see post-extract
# in Makefile.common).
#
# The Bazel path needs zakinko/bazel9.  Bazel needs a JVM to bootstrap, and
# mk/java-vm.mk offers openjdk21 on NetBSD only for x86_64, i386 and aarch64.
# Of those, Bazel itself turns i386 away:
#
#	src/tools/singlejar/mapped_file_posix.inc
#	#error This code for 64 bit Unix.	(wants __SIZEOF_POINTER__ == 8)
#
# That leaves x86_64 and aarch64.  Everywhere else Bazel will not build, so
# gyp is the default there.
#
# Only NetBSD/x86_64 has actually been measured.  aarch64 is counted because
# both conditions -- a JDK and 64 bits -- hold, not because anyone built it.
.if ${OPSYS} != "NetBSD" || \
    (${MACHINE_ARCH} != "x86_64" && ${MACHINE_ARCH} != "aarch64")
PKG_SUGGESTED_OPTIONS+=	gyp
.endif

.include "../../mk/bsd.options.mk"

# How it stops when the default is overridden and Bazel is asked for anyway.
# Without this the build walks into the ONLY_FOR_PLATFORM of zakinko/bazel9
# and stops with "bazel-9.2.0 is not available for this platform", which reads
# as a missing package rather than as the wrong choice of option.
.if empty(PKG_OPTIONS:Mgyp) && (${OPSYS} != "NetBSD" || \
    (${MACHINE_ARCH} != "x86_64" && ${MACHINE_ARCH} != "aarch64"))
PKG_FAIL_REASON+=	"The bazel build needs zakinko/bazel9, which builds"
PKG_FAIL_REASON+=	"only on NetBSD x86_64 and aarch64."
PKG_FAIL_REASON+=	"Set PKG_OPTIONS.mozc=gyp to build mozc here."
.endif

# How far the gyp path reaches is build_mozc.py's decision.  A patch adds
# NetBSD, so NetBSD works, as does the Linux upstream already handles.  On
# FreeBSD or SunOS it stops with
#
#	CRITICAL: target_platform FreeBSD is invalid.
#
# which says why, so no platform list is narrowed here.

# Either path produces the same version string, so the two are interchangeable
# at run time.  patch-build__tools_mozc__version.py says why that needs saying.
