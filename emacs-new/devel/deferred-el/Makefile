# $NetBSD$

DISTNAME=	deferred-0.5.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}deferred-el-0.5.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=kiwanami/}
GITHUB_PROJECT=	emacs-deferred
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/emacs-deferred-0.5.1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/kiwanami/emacs-deferred/
COMMENT=	Deferred and Concurrent - simple asynchronous functions for Emacs Lisp
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/deferred

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/deferred
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/deferred; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
