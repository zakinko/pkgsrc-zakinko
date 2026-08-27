# $NetBSD$

PKG_OPTIONS_VAR=	PKG_OPTIONS.mozc
PKG_SUPPORTED_OPTIONS=	gyp

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
#	src/tools/singlejar/port.h
#	#error This code for 64 bit Unix.
#
# So bazel exists on x86_64 and aarch64 and nowhere else, and everywhere
# else the gyp build -- which needs only python and ninja -- is the only
# one that can run.  Default to it there.
#
# Note that only x86_64 has been measured.  aarch64 is included because the
# JDK and the 64-bit requirement are both satisfied, not because anyone has
# built it: zakinko/bazel9 carries no aarch64 branch and was built on amd64.
.if ${OPSYS} != "NetBSD" || \
    (${MACHINE_ARCH} != "x86_64" && ${MACHINE_ARCH} != "aarch64")
PKG_SUGGESTED_OPTIONS+=	gyp
.endif

.include "../../mk/bsd.options.mk"

# The default above only chooses; it does not stop anyone from asking for the
# bazel build on a platform where bazel cannot exist.  Without this the build
# fails while resolving TOOL_DEPENDS, and the message names zakinko/bazel9
# rather than mozc, which reads as a missing package rather than as a wrong
# choice.
.if empty(PKG_OPTIONS:Mgyp) && (${OPSYS} != "NetBSD" || \
    (${MACHINE_ARCH} != "x86_64" && ${MACHINE_ARCH} != "aarch64"))
PKG_FAIL_REASON+=	"The bazel build needs zakinko/bazel9, which builds"	\
			"only on NetBSD x86_64 and aarch64."			\
			"Set PKG_OPTIONS.mozc=gyp to build mozc here."
.endif

# Both builds produce the same version string, so packages built either way
# are interchangeable at run time; see patch-build__tools_mozc__version.py
# for why that needs saying.
