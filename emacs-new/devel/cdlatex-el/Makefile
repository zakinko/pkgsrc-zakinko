# $NetBSD$

DISTNAME=	cdlatex-4.18.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}cdlatex-el-4.18.5
CATEGORIES=	devel
MASTER_SITES=	https://elpa.nongnu.org/nongnu/
EXTRACT_SUFX=	.tar

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://elpa.nongnu.org/nongnu/cdlatex.html
COMMENT=	Fast input methods for LaTeX environments and math
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}auctex-[0-9]*:../../print/auctex

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/cdlatex

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/auctex -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/cdlatex

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
