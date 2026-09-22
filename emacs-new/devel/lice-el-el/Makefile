# $NetBSD$

DISTNAME=	lice-el-0.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}lice-el-el-0.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=buzztaiki/}
GITHUB_PROJECT=	lice-el
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/buzztaiki/lice-el/
COMMENT=	License and header template for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/lice-el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/lice-el
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/lice-el; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
