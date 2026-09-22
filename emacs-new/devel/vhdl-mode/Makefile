# $NetBSD$

DISTNAME=	vhdl-mode-3.39.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}vhdl-mode-3.39.3
CATEGORIES=	devel
MASTER_SITES=	https://iis-people.ee.ethz.ch/~zimmi/emacs/
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/5e/
EXTRACT_SUFX=	.tar.gz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://iis-people.ee.ethz.ch/~zimmi/emacs/vhdl-mode.html
COMMENT=	VHDL-mode for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/vhdl-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el site-start.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/vhdl-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/vhdl-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
