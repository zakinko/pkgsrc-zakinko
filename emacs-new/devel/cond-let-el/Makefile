# $NetBSD$

DISTNAME=	cond-let-1.1.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}cond-let-el-1.1.4
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=tarsius/}
GITHUB_PROJECT=	cond-let
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/tarsius/cond-let/
COMMENT=	Additional and improved binding conditionals for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/cond-let

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/cond-let

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
