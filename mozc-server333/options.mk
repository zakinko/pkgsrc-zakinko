# $NetBSD$

PKG_OPTIONS_VAR=	PKG_OPTIONS.mozc
PKG_SUPPORTED_OPTIONS=	bazel gyp
PKG_SUGGESTED_OPTIONS=	gyp

.include "../../mk/bsd.prefs.mk"

# mozc can be built either with bazel, which is what upstream tests, or with
# gyp, which upstream keeps in maintenance mode.  3.33.6089 is the last
# release that carries gyp at all: the next tag, 3.33.6133, has neither
# src/build_mozc.py nor src/gyp/.
#
# Both builds produce all four programs here.  GYP has no mozc_renderer
# target for Unix upstream -- renderer.gyp defines it only under OS=="win"
# and OS=="mac" -- but the sources are present and
# patch-renderer_renderer.gyp adds the target, so the gyp path is not
# missing anything the bazel path has.
#
# The bazel path needs a JVM, and mk/java-vm.mk offers openjdk21 on NetBSD
# only for x86_64, i386 and aarch64 (_ONLY_FOR_PLATFORMS.openjdk21).  Of
# those, bazel's own singlejar refuses 32-bit outright:
#
#	src/tools/singlejar/mapped_file_posix.inc
#	#error This code for 64 bit Unix.
#
# So bazel exists on x86_64 and aarch64 and nowhere else, and everywhere
# else the gyp build -- which needs only python and ninja -- is the only
# one that can run.  Default to it there.
#
# Note that only x86_64 has been measured.  aarch64 is included because the
# JDK and the 64-bit requirement are both satisfied, not because anyone has
# built it: zakinko/bazel9 carries no aarch64 branch and was built on amd64.
#
# gyp is the default on every platform, including the two where bazel works.
# It needs only python and ninja, it builds the same four programs, and both
# paths emit the same version string, so a package built either way is
# interchangeable at run time.  Defaulting to the one that runs everywhere
# keeps the package uniform across the platforms pkgsrc covers; ask for bazel
# where you want it.

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
# instead fails while resolving TOOL_DEPENDS, and the message names
# zakinko/bazel9 rather than mozc, which reads as a missing package rather than
# as a platform that has no bazel.
.if ${MOZC_BUILDER} == "bazel" && (${OPSYS} != "NetBSD" || \
    (${MACHINE_ARCH} != "x86_64" && ${MACHINE_ARCH} != "aarch64"))
MOZC_BUILDER=	gyp
WARNINGS+=	"[options.mk] bazel builds only on NetBSD x86_64 and aarch64;"
WARNINGS+=	"[options.mk] building mozc with gyp instead."
.endif

# Both builds produce the same version string, so packages built either way
# are interchangeable at run time; see patch-build__tools_mozc__version.py
# for why that needs saying.
