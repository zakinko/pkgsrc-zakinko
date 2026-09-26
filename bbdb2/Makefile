# $NetBSD$

DISTNAME=		bbdb-2.35
PKGNAME=		${EMACS_PKGNAME_PREFIX}${DISTNAME:C/bbdb/bbdb2/}
PKGREVISION=		1
CATEGORIES=		zakinko misc mail news
MASTER_SITES=		${MASTER_SITE_SOURCEFORGE:=bbdb/}

MAINTAINER=		pkgsrc-users@NetBSD.org
HOMEPAGE=		https://sourceforge.net/projects/bbdb/
COMMENT=		Insidious Big Brother DataBase, a rolodex-like database Emacs program
LICENSE=		gnu-gpl-v1

# 2.35 is the last BBDB for the Emacsen before 23; modern ones use bbdb3.
# XEmacs is not offered: bbdb comes with xemacs-packages, and building
# this one for XEmacs needs timezone.el, which only xemacs-packages
# ships, while the two conflict.  It could never build there.
EMACS_VERSIONS_ACCEPTED=	emacs20 emacs21 emacs21nox

# in case old one exists
CONFLICTS+=		bbdb-[0-9]*
CONFLICTS+=		bbdb3-[0-9]*

USE_PKGLOCALEDIR=	yes
CONFIGURE_ARGS+=	--enable-rmail
GNU_CONFIGURE=		yes
BUILD_TARGET=		all mhe
USE_TOOLS+=		makeinfo
INFO_FILES=		yes
LISPDIR=		${EMACS_LISPPREFIX}/bbdb
INSTALLATION_DIRS=	${EMACS_INFOPREFIX}
MAKE_JOBS_SAFE=		no

.include "../../editors/emacs/modules.mk"

post-extract:
	${RM} -rf ${WRKSRC}/lisp/*.elc

# configure takes the emacs on PATH unless told; with a newer Emacs
# installed alongside, that one ran and its start-up messages ended up in
# lisp/Makefile.
CONFIGURE_ARGS+=	--with-emacs=${EMACS_BIN}

do-install:
	${MKDIR} ${DESTDIR}${LISPDIR}
	${INSTALL_DATA} ${WRKSRC}/lisp/*.el ${DESTDIR}${LISPDIR}
	${INSTALL_DATA} ${WRKSRC}/lisp/*.elc ${DESTDIR}${LISPDIR}
	cd ${WRKSRC}/texinfo; for f in bbdb.info bbdb.info-[0-9]*; do	\
		${TEST} ! -f "$$f" ||					\
		${INSTALL_DATA} "$$f" ${DESTDIR}${PREFIX}/${PKGINFODIR};\
	done

.include "../../mk/bsd.pkg.mk"
