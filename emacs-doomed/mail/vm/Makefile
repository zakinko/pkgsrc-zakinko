# $NetBSD: Makefile,v 1.48 2026/09/25 09:48:10 wiz Exp $

DISTNAME=	vm-8.3.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
CATEGORIES=	mail
MASTER_SITES=	https://gitlab.com/emacs-vm/vm/-/archive/${PKGVERSION_NOREV}/

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/emacs-vm/vm
COMMENT=	Advanced mail user agent for Emacs

USE_TOOLS+=	makeinfo gmake gtar autoconf
# The 8.3 manual's node pointers are rejected by makeinfo 4.8 in NetBSD's
# base system (it removes vm.info and fails); texinfo 5 accepts them.
TEXINFO_REQD+=	5.0
GNU_CONFIGURE=	yes
INFO_FILES=	yes

MAKEFLAGS+=	EMACS=${EMACS_BIN:Q}
MAKE_ENV+=	LISPDIR=${EMACS_LISPPREFIX}/vm
MAKE_ENV+=	INFODIR=${INFODIR:Q}
MAKE_ENV+=	PIXMAPDIR=${PIXMAPDIR:Q}
MAKE_ENV+=	BINDIR=${PREFIX:Q}/bin
PLIST_SUBST+=	PIXMAPDIR=${PIXMAPDIR:S/^${PREFIX}\///:Q}

# configure decides lispdir and writes it into the generated Makefile, so
# the MAKE_ENV setting never reaches it and the files land in an
# unversioned share/emacs/site-lisp/vm, which then does not match PLIST.
CONFIGURE_ARGS+=	--with-lispdir=${EMACS_LISPPREFIX}/vm
# configure takes the Emacs from --with-emacs, or else "emacs" on PATH,
# which is whichever Emacs bin/emacs points at.  MAKEFLAGS does not reach
# EMACS_PROG in the generated Makefiles.
CONFIGURE_ARGS+=	--with-emacs=${EMACS_BIN:Q}

# 8.3 needs GNU Emacs 28.1 or later.
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs30 emacs31

INSTALLATION_DIRS=	bin ${EMACS_INFOPREFIX} ${EMACS_LISPPREFIX}/vm	\
			${PIXMAPDIR}

PIXMAPDIR=		${PIXMAPDIR.${EMACS_FLAVOR}}
PIXMAPDIR.emacs=	${PREFIX:Q}/share/vm/pixmaps
PIXMAPDIR.xemacs=	${EMACS_LISPPREFIX:H}/etc/vm

# The release tarball is the tagged tree, without a generated configure.
pre-configure:
	cd ${WRKSRC} && autoconf

.include "../../editors/emacs/modules.mk"

.include "../../mk/bsd.pkg.mk"
