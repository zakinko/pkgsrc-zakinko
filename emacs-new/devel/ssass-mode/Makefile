# $NetBSD$

DISTNAME=	ssass-mode-0.2.20200211
PKGNAME=	${EMACS_PKGNAME_PREFIX}ssass-mode-0.2.20200211
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=AdamNiederer/}
GITHUB_PROJECT=	ssass-mode
GITHUB_TAG=	96f557887ad97a0066a60c54f92b7234b8407016
WRKSRC=		${WRKDIR}/ssass-mode-96f557887ad97a0066a60c54f92b7234b8407016

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/AdamNiederer/ssass-mode/
COMMENT=	Write Sass in Emacs without a Turing Machine
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ssass-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/ssass-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
