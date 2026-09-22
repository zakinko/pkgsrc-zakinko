# $NetBSD$
#
# The platforms for which upstream publishes a binary release of Go, and
# the name each archive carries on dl.google.com.
#
# Two things read this file: lang/go-bin builds ONLY_FOR_PLATFORM and
# DISTFILES from it, and lang/go/version.mk asks whether GO_TYPE=bin can
# be honoured on this platform.  Keeping the list in one place means
# adding a platform is a single line, and the two can never disagree.
#
# Upstream also publishes aix/ppc64, plan9 and windows archives; only the
# ones pkgsrc has a MACHINE_ARCH spelling for are listed.

.if !defined(GO_BIN_PLATFORMS_MK)
GO_BIN_PLATFORMS_MK=	# defined

GO_BIN_PLATFORMS=	# empty

.for _platform_ _archive_ in \
	Darwin-*-x86_64      darwin-amd64 \
	Darwin-*-aarch64     darwin-arm64 \
	DragonFly-*-x86_64   dragonfly-amd64 \
	FreeBSD-*-i386       freebsd-386 \
	FreeBSD-*-x86_64     freebsd-amd64 \
	FreeBSD-*-*arm*      freebsd-arm \
	FreeBSD-*-aarch64    freebsd-arm64 \
	Linux-*-i386         linux-386 \
	Linux-*-x86_64       linux-amd64 \
	Linux-*-*arm*        linux-armv6l \
	Linux-*-aarch64      linux-arm64 \
	Linux-*-loongarch64  linux-loong64 \
	Linux-*-mips         linux-mips \
	Linux-*-mips64       linux-mips64 \
	Linux-*-mips64el     linux-mips64le \
	Linux-*-mipsel       linux-mipsle \
	Linux-*-powerpc64    linux-ppc64 \
	Linux-*-powerpc64le  linux-ppc64le \
	Linux-*-riscv64      linux-riscv64 \
	Linux-*-s390x        linux-s390x \
	NetBSD-*-i386        netbsd-386 \
	NetBSD-*-x86_64      netbsd-amd64 \
	NetBSD-*-earmv[67]hf netbsd-arm \
	NetBSD-*-aarch64     netbsd-arm64 \
	OpenBSD-*-i386       openbsd-386 \
	OpenBSD-*-x86_64     openbsd-amd64 \
	OpenBSD-*-*arm*      openbsd-arm \
	OpenBSD-*-aarch64    openbsd-arm64 \
	OpenBSD-*-powerpc64  openbsd-ppc64 \
	OpenBSD-*-riscv64    openbsd-riscv64 \
	SunOS-*-x86_64       illumos-amd64 \
	AIX-*-powerpc64      aix-ppc64

GO_BIN_PLATFORMS+=		${_platform_}
GO_BIN_ARCHIVE.${_platform_}=	${_archive_}
.endfor

# Does this machine have one?
GO_BIN_SUPPORTED=	no
.for _platform_ in ${GO_BIN_PLATFORMS}
.  if !empty(MACHINE_PLATFORM:M${_platform_})
GO_BIN_SUPPORTED=	yes
.  endif
.endfor

.endif  # GO_BIN_PLATFORMS_MK
