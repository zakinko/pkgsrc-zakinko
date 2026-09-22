# $NetBSD$

DISTNAME=	wfnames-1.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}wfnames-el-1.2
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=thierryvolpiatto/}
GITHUB_PROJECT=	wfnames
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/thierryvolpiatto/wfnames/
COMMENT=	GNU Emacs mode to edit filenames, similar to wdired
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/wfnames

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/wfnames

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
