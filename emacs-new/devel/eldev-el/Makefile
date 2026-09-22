# $NetBSD$

DISTNAME=	eldev-1.11.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}eldev-el-1.11.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacs-eldev/}
GITHUB_PROJECT=	eldev
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://emacs-eldev.github.io/eldev/
COMMENT=	Emacs Lisp Development Tool
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/eldev

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/eldev
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/eldev; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
