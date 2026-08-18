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

# lang/zig/application.mk の zig-vendor-packages が post-extract で
# zig fetch を走らせるので、組む段で網が要る。あちらの TODO
# ("save to distfiles") が片付くまでは外せない。
ALLOW_NETWORK_ACCESS=yes

.include "zig-depends.mk"

.include "../../lang/zig/application.mk"
.include "../../mk/bsd.pkg.mk"
