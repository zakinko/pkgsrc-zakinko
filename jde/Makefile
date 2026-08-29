# $NetBSD$

DISTNAME=	jde-2.3.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
PKGREVISION=	4
CATEGORIES=	editors devel java
MASTER_SITES=	${MASTER_SITE_LOCAL}
# The "real" site has silly naming conventions:
##MASTER_SITES=	http://jdee.sunsite.dk/

MAINTAINER=	pkgsrc-users@NetBSD.org
#HOMEPAGE=	http://jdee.sunsite.dk/
COMMENT=	Full-featured Java editing mode for emacs
LICENSE=	gnu-gpl-v2

DEPENDS+=	${EMACS_PKGNAME_PREFIX}speedbar>=0.14rc2:../../editors/speedbar
DEPENDS+=	${EMACS_PKGNAME_PREFIX}eieio>=0.17:../../lang/eieio
DEPENDS+=	${EMACS_PKGNAME_PREFIX}semantic>=1.4rc13:../../devel/semantic
DEPENDS+=	${EMACS_PKGNAME_PREFIX}elib>=1.0:../../devel/elib

USE_TOOLS+=	pax

WRKSRC=		${WRKDIR}/${DISTNAME}/lisp

# XEmacs has its own JDE package
EMACS_VERSIONS_ACCEPTED=	emacs21		# XXX Won't compile with emacs20...

.include "../../editors/emacs/modules.mk"

# The bundled makefile sets EMACS=emacs, so the build used whatever emacs was
# first on PATH rather than the one this package was built for.  The line here
# was meant to override it but did neither: PKGSRC_MAKE_ENV is computed by
# pkgsrc and not something a package appends to, and EMACS is not defined --
# modules.mk defines EMACS_BIN.  devel/emacs-ilisp has it right.
MAKE_ENV+=		EMACS=${EMACS_BIN}
MAKE_ENV+=		EMACS_LISPPREFIX=${EMACS_LISPPREFIX}

INSTALLATION_DIRS+=	share/doc/jde
INSTALLATION_DIRS+=	share/jde

NO_CONFIGURE=	yes

MAKE_FILE=	makefile

post-extract:
	${RUN} ${RMDIR} ${WRKDIR}/${DISTNAME}/java/classes

do-install:
	${INSTALL_DATA_DIR} ${DESTDIR}${EMACS_LISPPREFIX}/jde
	cd ${WRKDIR}/${DISTNAME}/doc &&					\
		pax -s',^src.*,,' -s',.*\.nosearch.*,,'		\
			-rw * ${DESTDIR}${PREFIX}/share/doc/jde
	cd ${WRKDIR}/${DISTNAME} &&					\
		pax -s',^java/classes.*,,' -s',^java/src.*,,'	\
			-s',.*\.nosearch.*,,' -rw java			\
			${DESTDIR}${PREFIX}/share/jde
	cd ${WRKDIR}/${DISTNAME} &&					\
		pax -rw -s ',.*\.orig$$,,' lisp			\
			${DESTDIR}${EMACS_LISPPREFIX}/jde

.include "../../mk/java-vm.mk"
.include "../../mk/bsd.pkg.mk"
