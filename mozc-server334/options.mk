# $NetBSD$

PKG_OPTIONS_VAR=	PKG_OPTIONS.mozc
PKG_SUPPORTED_OPTIONS=	bazel gyp
PKG_SUGGESTED_OPTIONS=	gyp

.include "../../mk/bsd.prefs.mk"

# 3.34.6239 ships no GYP: no src/build_mozc.py, no src/gyp/, not one .gyp file.
# Bazel is the only way upstream builds it.  GYP went away in 3.33.6133, not in
# 3.34, so 3.33.6089 is the last tag that still has it, and the gyp option
# brings that scaffolding across from the 3.33.6089 tarball (see post-extract
# in Makefile.common).
#
# The Bazel path needs devel/bazel9.  Bazel needs a JVM to bootstrap, and
# mk/java-vm.mk offers openjdk21 on NetBSD only for x86_64, i386 and aarch64.
# Of those, Bazel itself turns i386 away:
#
#	src/tools/singlejar/mapped_file_posix.inc
#	#error This code for 64 bit Unix.	(wants __SIZEOF_POINTER__ == 8)
#
# That leaves x86_64 and aarch64.  Everywhere else Bazel will not build.
#
# Only NetBSD/x86_64 has actually been measured.  aarch64 is counted because
# both conditions -- a JDK and 64 bits -- hold, not because anyone built it.
#
# gyp is the default on every platform, including the two where Bazel works.
# It needs only python and ninja, it is the same code, and both paths emit the
# same version string, so a package built either way is interchangeable at run
# time.  Defaulting to the one that runs everywhere keeps the package uniform
# across the platforms pkgsrc covers; ask for bazel where you want it.

.include "../../mk/bsd.options.mk"

# Which builder to use.  The Makefiles test MOZC_BUILDER rather than
# PKG_OPTIONS, so that the fallback below is decided in one place.
MOZC_BUILDER=	gyp
.if !empty(PKG_OPTIONS:Mbazel)
MOZC_BUILDER=	bazel
.endif

# Before the bazel option existed, turning gyp off was how you asked for
# bazel.  PKG_OPTIONS.mozc=-gyp still means that; keep it working rather than
# quietly building the other way than the one that was asked for.
.if empty(PKG_OPTIONS:Mgyp) && empty(PKG_OPTIONS:Mbazel)
MOZC_BUILDER=	bazel
.endif

# Asking for bazel where bazel cannot be built is not a reason to stop: gyp
# builds the same programs there.  Fall back to it and say so.  Stopping
# instead walks into the ONLY_FOR_PLATFORM of devel/bazel9 and reports
# "bazel-9.2.0 is not available for this platform", which reads as a missing
# package rather than as a platform that has no bazel.
.if ${MOZC_BUILDER} == "bazel" && (${OPSYS} != "NetBSD" || \
    (${MACHINE_ARCH} != "x86_64" && ${MACHINE_ARCH} != "aarch64"))
MOZC_BUILDER=	gyp
WARNINGS+=	"[options.mk] bazel builds only on NetBSD x86_64 and aarch64;"
WARNINGS+=	"[options.mk] building mozc with gyp instead."
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
