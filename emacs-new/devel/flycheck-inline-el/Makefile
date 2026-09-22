# $NetBSD$

DISTNAME=	flycheck-inline-0pre20200808
PKGNAME=	${EMACS_PKGNAME_PREFIX}flycheck-inline-el-0pre20200808
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=flycheck/}
GITHUB_PROJECT=	flycheck-inline
GITHUB_TAG=	8e00b4c5951a9515a450a14aefe92e9f6ddcfbde
WRKSRC=		${WRKDIR}/flycheck-inline-8e00b4c5951a9515a450a14aefe92e9f6ddcfbde

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/flycheck/flycheck-inline
COMMENT=	Display Flycheck errors inline
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}flycheck-mode-[0-9]*:../../textproc/flycheck-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/flycheck-inline

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/flycheck-inline
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/flycheck-inline; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
