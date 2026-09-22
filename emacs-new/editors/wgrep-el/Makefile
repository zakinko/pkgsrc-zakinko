# $NetBSD$

DISTNAME=	wgrep-3.0.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}wgrep-el-3.0.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=mhayashi1120/}
GITHUB_PROJECT=	Emacs-wgrep
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/Emacs-wgrep-3.0.0

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/mhayashi1120/Emacs-wgrep/
COMMENT=	Writable grep buffer and apply the changes to files
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/wgrep

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/wgrep

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
