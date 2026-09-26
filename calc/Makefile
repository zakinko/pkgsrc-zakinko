# $NetBSD$

DISTNAME=	calc-2.02f
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
PKGREVISION=	5
CATEGORIES=	math
MASTER_SITES=	${MASTER_SITE_GNU:=calc/}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://directory.fsf.org/project/calc/
COMMENT=	Advanced Calculator for GNU Emacs
LICENSE=	gnu-gpl-v1

EMACS_VERSIONS_ACCEPTED=	emacs21 emacs21nox emacs20 \
				xemacs215 xemacs215nox xemacs214 xemacs214nox

.include "../../editors/emacs/modules.mk"

MAKE_ENV+=	EMACS=${EMACS_FLAVOR}

USE_TOOLS+=	makeinfo
INFO_FILES=	yes

INSTALLATION_DIRS=	${EMACS_INFOPREFIX} ${EMACS_LISPPREFIX}/calc

do-install:
	${INSTALL_DATA} ${WRKSRC}/*.el ${WRKSRC}/*.elc			\
		${WRKSRC}/calccard.tex ${DESTDIR}${EMACS_LISPPREFIX}/calc
	${RUN} cd ${WRKSRC}; for f in *.info *.info-[0-9]*; do			\
		${TEST} ! -f "$$f" ||					\
		${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_INFOPREFIX};	\
	done

# Register the entry points instead of telling the user to paste autoloads
# into ~/.emacs.  editors/emacs20 and emacs21 install site-lisp/site-start.el,
# which loads everything here at startup.
post-install: calc-site-start
.PHONY: calc-site-start
calc-site-start:
	${INSTALL_DATA_DIR} ${DESTDIR}${EMACS_LISPPREFIX}/site-start.d
	${INSTALL_DATA} ${FILESDIR}/site-start.el \
		${DESTDIR}${EMACS_LISPPREFIX}/site-start.d/20-calc.el

.include "../../mk/bsd.pkg.mk"
