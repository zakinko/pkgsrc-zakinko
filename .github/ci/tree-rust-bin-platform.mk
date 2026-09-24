# $NetBSD$
#
# The platforms lang/rust-bin has a binary for, and whether this machine
# is one of them.
#
# Two things read this file: this package builds ONLY_FOR_PLATFORM from
# it, and lang/rust/rust.mk asks whether RUST_TYPE=bin can be honoured
# here.  Keeping the list in one place means the two can never disagree,
# which is the whole point -- answering "yes" where the package then
# refuses the platform is the breakage this exists to avoid.
#
# Same shape as lang/go-bin/platform.mk.
#
# The conditionals below read OPSYS, OS_VERSION and MACHINE_PLATFORM, so
# pull in the preferences here rather than relying on whoever includes
# this file having done it first.  lang/rust-bin/Makefile sets
# ONLY_FOR_PLATFORM before it reaches bsd.prefs.mk, and including this
# there without the line below gave
#	Malformed conditional '${OPSYS} != "NetBSD" || ...'
.include "../../mk/bsd.fast.prefs.mk"

.if !defined(PLATFORM_SUPPORTS_RUST_BIN)

# Built by upstream and published on static.rust-lang.org.
.for rust_bin_platform in \
	Darwin-*-aarch64 Darwin-*-x86_64 \
	FreeBSD-*-x86_64 \
	Linux-*-aarch64 Linux-*-i386 Linux-*-x86_64 \
	NetBSD-*-x86_64 \
	SunOS-*-x86_64
RUST_BIN_PLATFORMS+=	${rust_bin_platform}
.endfor

# Built by he@NetBSD.org and placed in the pkgsrc distfile mirror.  These
# bootstraps were made for NetBSD 9 or newer; -8's gcc is too old.
.for rust_bin_platform in \
	NetBSD-*-aarch64 NetBSD-*-aarch64eb \
	NetBSD-*-earmv7hf NetBSD-*-earmv6hf \
	NetBSD-*-i386 NetBSD-*-powerpc NetBSD-*-sparc64 \
	NetBSD-*-mipsel NetBSD-*-riscv64
.  if ${OPSYS} != "NetBSD" || empty(OS_VERSION:M[0-8].*)
RUST_BIN_PLATFORMS+=	${rust_bin_platform}
.  endif
.endfor

.for rust_bin_platform in ${RUST_BIN_PLATFORMS}
.  if !empty(MACHINE_PLATFORM:M${rust_bin_platform})
PLATFORM_SUPPORTS_RUST_BIN?=	yes
.  endif
.endfor
PLATFORM_SUPPORTS_RUST_BIN?=	no

.endif # !defined(PLATFORM_SUPPORTS_RUST_BIN)
