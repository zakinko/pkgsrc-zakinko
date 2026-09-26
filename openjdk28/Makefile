# $NetBSD$
#
# mainline (openjdk/jdk = 28-dev) を NetBSD で建てるための実験用。pkgsrc に
# 出すのは LTS の openjdk25 で、こちらは移植の作業場である。
#
# 建てているのは upstream そのものではなく zakinko/jdk の netbsd-amd64 で、
# そこに移植の commit を一件ずつ積んでいる。通ったものを upstream へ PR として
# 出し、受かったぶんを削っていく形にする。

DISTNAME=	jdk-netbsd-amd64
PKGNAME=	openjdk28-1.28.0.0.0.20260829
CATEGORIES=	lang
MASTER_SITES=	${MASTER_SITE_GITHUB:=zakinko/}
GITHUB_PROJECT=	jdk
GITHUB_TAG=	netbsd-amd64

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	https://openjdk.java.net/
COMMENT=	Open-source implementation of the Java Platform, 28 (development)
LICENSE=	gnu-gpl-v2

# 28 を建てるには 26 以上の JDK が要る (DEFAULT_ACCEPTABLE_BOOT_VERSIONS)。
# NetBSD にはまだ無いので、次のどちらかで用意する。
#
#   1. Linux から cross build する (NetBSD-i386 の jdk28-netbsd-cross.yml)
#   2. NetBSD で 25 を建て、それを boot にする (openjdk25 と BOOT_RELAX)
#
# どちらも「借りた卵」で、一度通れば NetBSD の中で自給できるようになる。
.if !defined(OPENJDK28_BOOT_JDK)
PKG_FAIL_REASON+=	"OPENJDK28_BOOT_JDK に 26 以上の JDK の path を渡してください"
.endif

ONLY_FOR_PLATFORM=	NetBSD-*-x86_64

.include "../../mk/bsd.pkg.mk"
