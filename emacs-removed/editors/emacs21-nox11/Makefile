# $NetBSD: Makefile,v 1.15 2021/10/06 15:40:15 nia Exp $

PKGNAME=	emacs21-nox11-${EMACSVERSION}a
PKGREVISION=	15
CATEGORIES=	editors
COMMENT_EXTRA=	: non-X11 version

CONFLICTS+=	emacs21-[0-9]*

MKPIE_SUPPORTED=	no

CONFIGURE_ARGS+=	--without-x

.include "../../zakinko/emacs21/Makefile.common"
.include "../../mk/bsd.pkg.mk"
