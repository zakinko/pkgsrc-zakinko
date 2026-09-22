# $NetBSD$

DISTNAME=	kind-icon-0.2.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}kind-icon-el-0.2.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=jdtsmith/}
GITHUB_PROJECT=	kind-icon
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/jdtsmith/kind-icon/
COMMENT=	Completion kind icons
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}svg-lib-el-[0-9]*:../../devel/svg-lib-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/kind-icon

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/svg-lib -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/kind-icon

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
