# $NetBSD$

DISTNAME=	pos-tip-0.4.7
PKGNAME=	${EMACS_PKGNAME_PREFIX}pos-tip-el-0.4.7
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=pitkali/}
GITHUB_PROJECT=	pos-tip
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/pitkali/pos-tip/
COMMENT=	Show tooltip at point
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/pos-tip

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/pos-tip
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/pos-tip; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
