# $NetBSD$

DISTNAME=	emacs-aio-1.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs-aio-el-1.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=skeeto/}
GITHUB_PROJECT=	emacs-aio
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/skeeto/emacs-aio/
COMMENT=	Async and await functions for Emacs Lisp
LICENSE=	unlicense

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emacs-aio

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile aio.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/emacs-aio

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
