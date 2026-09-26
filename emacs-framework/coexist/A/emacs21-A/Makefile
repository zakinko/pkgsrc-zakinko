# $NetBSD: Makefile,v 1.51 2025/08/30 22:44:55 wiz Exp $

PKGREVISION=	52
CATEGORIES=	editors

# emacs21-nox11 とは CONFLICTS しない。nox 版は EMACS_TAG の下に入る。

USE_TOOLS+=	imake

MKPIE_SUPPORTED=	no

.include "options.mk"

.include "../../netbsd-i386-3e/emacs21-A/Makefile.common"

.include "../../mk/bsd.pkg.mk"

