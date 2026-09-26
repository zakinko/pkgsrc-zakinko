# $NetBSD: Makefile,v 1.4 2024/08/13 19:41:04 wiz Exp $

DISTNAME=	zls-0.16.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=zigtools/}
GITHUB_PROJECT=	zls
GITHUB_TAG=	${PKGVERSION_NOREV}

COMMENT=	Language Server for zig
MAINTAINER=	nikita@NetBSD.org
HOMEPAGE=	https://github.com/zigtools/zls/
LICENSE=	mit

ZIGSTRIP=	no

# lang/zig/application.mk fetches ZIG_PACKAGE_DEPENDS with "zig fetch" in
# post-extract, so the build needs the network.  Its own TODO says these
# should be saved as distfiles instead; until then this has to stay.
ALLOW_NETWORK_ACCESS=yes

.include "zig-depends.mk"

.include "../../lang/zig/application.mk"
.include "../../mk/bsd.pkg.mk"
