# $NetBSD$

DISTNAME=	load-relative-1.3.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}load-relative-el-1.3.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=rocky/}
GITHUB_PROJECT=	emacs-load-relative
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/emacs-load-relative-1.3.2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/rocky/emacs-load-relative/
COMMENT=	Relative loads for Emacs Lisp files
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/load-relative

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/load-relative
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/load-relative; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
