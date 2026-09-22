# $NetBSD$

DISTNAME=	auto-complete-1.5.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}auto-complete-el-1.5.1
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=auto-complete/}
GITHUB_PROJECT=	auto-complete
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/auto-complete/auto-complete/
COMMENT=	Auto-complete package
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}popup-el-[0-9]*:../../editors/popup-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/auto-complete

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/popup -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/auto-complete

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
