# $NetBSD: Makefile,v 1.29 2026/09/25 09:48:11 wiz Exp $

DISTNAME=	lookup-1.4.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
PKGREVISION=	3
CATEGORIES=	textproc
MASTER_SITES=	http://openlab.jp/edict/lookup/dist/

MAINTAINER=	uebayasi@NetBSD.org
HOMEPAGE=	http://openlab.jp/edict/lookup/index.html.ja
COMMENT=	Electric dictionary agent for Emacs

MAKE_JOBS_SAFE=	no

DEPENDS+=	eblook>=1.4:../../textproc/eblook

# lookup 1.4.1 uses the old-style backquote, (` (...)), which Emacs 27
# removed, so it cannot build on a current Emacs.
EMACS_VERSIONS_ACCEPTED=	emacs20
EMACS_BUILDLINK=		# defined

GNU_CONFIGURE=	YES
MAKEFLAGS+=	lispdir=${EMACS_LISPPREFIX}/lookup
INFO_FILES=	yes

CONFIGURE_ARGS+=	${EMACS_FLAVOR}
# configure looks for the flavour's name on PATH, which is whatever
# bin/emacs points at (the newest Emacs installed), so an emacs20 build
# was byte-compiled by another Emacs.  Hand it the one this package is for.
CONFIGURE_ARGS+=	--with-emacs=${EMACS_BIN:Q}

.include "../../editors/emacs/modules.mk"

.include "../../devel/apel/buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
