# $NetBSD$

DISTNAME=	geiser-0.33.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}geiser-el-0.33.2
CATEGORIES=	devel
MASTER_SITES=	https://elpa.nongnu.org/nongnu/
EXTRACT_SUFX=	.tar

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://elpa.nongnu.org/nongnu/geiser.html
COMMENT=	Generic interaction mode between Emacs and different Scheme implementa
LICENSE=	modified-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/geiser

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/geiser

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
