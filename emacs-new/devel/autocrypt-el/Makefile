# $NetBSD$

DISTNAME=	autocrypt.el-e65fc01502e2c02914752c5b58c100d47db40b30
PKGNAME=	${EMACS_PKGNAME_PREFIX}autocrypt-el-0.4.2pre20260126
CATEGORIES=	devel
MASTER_SITES=	https://codeberg.org/pkal/autocrypt.el/archive/
DISTFILES=	e65fc01502e2c02914752c5b58c100d47db40b30${EXTRACT_SUFX}
DIST_SUBDIR=	${DISTNAME}
WRKSRC=		${WRKDIR}/autocrypt.el

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://codeberg.org/pkal/autocrypt.el
COMMENT=	Generic autocrypt implementation for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/autocrypt

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/autocrypt
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/autocrypt; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
