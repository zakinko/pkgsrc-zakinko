# $NetBSD: Makefile,v 1.15 2021/10/06 15:40:15 nia Exp $

PKGNAME=	emacs21-nox11-${EMACSVERSION}a
PKGREVISION=	17
CATEGORIES=	editors
COMMENT_EXTRA=	: non-X11 version

# CONFLICTS は無い。EMACS_TAG に -nox11 が付き、X 版と path を共有しない。
EMACS_TAG=	21.4-nox11

MKPIE_SUPPORTED=	no

CONFIGURE_ARGS+=	--without-x

.include "../../netbsd-i386-3e/emacs21-A/Makefile.common"
.include "../../mk/bsd.pkg.mk"
