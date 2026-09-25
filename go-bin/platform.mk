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
# The left column is what bootstrap/bootstrap leaves in MACHINE_ARCH,
# which is not always what uname(1) says or what upstream calls it.  The
# same machine is spelled several ways, so they are all written out here
# for whoever greps for one of them:
#
#	pkgsrc		uname -m / arch -s	upstream
#	i386		i386 i486 i586 i686	386
#	x86_64		amd64 x86_64		amd64
#	aarch64		arm64 aarch64		arm64
#	earmv6hf earmv7hf  arm armv6l armv7l	arm armv6l
#	ppc64		ppc64			ppc64
#	powerpc64	powerpc64		ppc64
#	powerpc64le	ppc64le			ppc64le
#	mipseb		mips			mips
#	mipsel		mips			mipsle
#	mips64eb	mips64			mips64
#	mips64el	mips64			mips64le
#	loongarch64	loongarch64		loong64
#	s390x		s390x			s390x
#	riscv64		riscv64			riscv64
#
# Linux passes uname -m through untouched apart from i?86 and ppc64le, so
# ppc64 stays ppc64 there while OpenBSD's arch -s says powerpc64.  Both
# are listed.
#
# mips is the exception, and the reason the four rows above do not read
# the way uname -m does.  Linux says "mips" on both a big-endian and a
# little-endian 32-bit box, and "mips64" on both 64-bit ones, so uname
# alone cannot pick an archive.  pkgsrc does not accept those two names:
# bsd.own.mk refuses MACHINE_ARCH=mips outright, and the canonical names
# are mipseb, mipsel, mips64eb and mips64el (mk/bsd.prefs.mk's
# _BIGENDIANCPUS and _LITTLEENDIANCPUS).  bootstrap's --machine-arch is
# how one says which it is.  Matching on the bare names instead would
# hand a little-endian box the big-endian archive, which installs and
# even answers "go version", then dies with SIGBUS on the first real
# build; leaving them out means such a box reports no binary Go for its
# platform, which is the better of the two.
#
# Deliberately absent, and why:
#
#	Plan 9		upstream ships plan9/386, plan9/amd64 and
#			plan9/arm, but pkgsrc does not run there: no
#			mk/platform/Plan9.mk, and bootstrap/bootstrap has
#			no Plan9 case.  The one attempt at a port
#			(9p.io/sources/contrib/staal1978/pkgsrc, 2013)
#			stops while building bmake.
#	Cygwin		upstream ships windows/386, windows/amd64 and
#			windows/arm64, and Cygwin is a pkgsrc platform,
#			but Go has no cygwin GOOS: lang/go/version.mk
#			derives GOOS from LOWER_OPSYS, so a Cygwin build
#			would ask for GOOS=cygwin, and the windows
#			toolchain produces PE binaries rather than the
#			Cygwin ones the rest of pkgsrc expects.  The
#			archives are .zip as well.
#	AIX rs6000	get_machine_arch_aix() returns rs6000 on POWER and
#			powerpc otherwise; only a --abi 64 bootstrap of
#			the latter reaches powerpc64, which is the one
#			spelling the 64-bit archive suits.

# The conditionals below read OPSYS, OS_VARIANT and MACHINE_PLATFORM.
# Pull in the preferences here so this file is safe wherever it is
# included, rather than relying on the includer having done it first.
.include "../../mk/bsd.fast.prefs.mk"

.if !defined(PLATFORM_SUPPORTS_GO_BIN)

GO_BIN_PLATFORMS=	# empty

.for go_platform go_archive in \
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
	Linux-*-mipseb       linux-mips \
	Linux-*-mipsel       linux-mipsle \
	Linux-*-mips64eb     linux-mips64 \
	Linux-*-mips64el     linux-mips64le \
	Linux-*-ppc64        linux-ppc64 \
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

GO_BIN_PLATFORMS+=		${go_platform}
GO_BIN_ARCHIVE.${go_platform}=	${go_archive}
.endfor

# pkgsrc spells Solaris and illumos alike in MACHINE_PLATFORM, but
# upstream publishes a separate archive for each, and lang/go/version.mk
# already tells them apart the same way.
.if ${OPSYS} == "SunOS" && ${OS_VARIANT} == "Solaris"
GO_BIN_ARCHIVE.SunOS-*-x86_64=	solaris-amd64
.endif

# Does this machine have one?
.for go_platform in ${GO_BIN_PLATFORMS}
.  if !empty(MACHINE_PLATFORM:M${go_platform})
PLATFORM_SUPPORTS_GO_BIN?=	yes
.  endif
.endfor
PLATFORM_SUPPORTS_GO_BIN?=	no

.endif # !defined(PLATFORM_SUPPORTS_GO_BIN)
