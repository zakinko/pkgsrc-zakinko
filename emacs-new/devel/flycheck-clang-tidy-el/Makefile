# $NetBSD$

DISTNAME=	flycheck-clang-tidy-0.3.0.20201116
PKGNAME=	${EMACS_PKGNAME_PREFIX}flycheck-clang-tidy-el-0.3.0.20201116
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ch1bo/}
GITHUB_PROJECT=	flycheck-clang-tidy
GITHUB_TAG=	f9ae7306bd6ca08b689b36c1e8f6f6b91d61db5f
WRKSRC=		${WRKDIR}/flycheck-clang-tidy-f9ae7306bd6ca08b689b36c1e8f6f6b91d61db5f

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ch1bo/flycheck-clang-tidy
COMMENT=	Flycheck syntax checker using clang-tidy
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}flycheck-mode-[0-9]*:../../textproc/flycheck-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/flycheck-clang-tidy

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/flycheck-clang-tidy
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/flycheck-clang-tidy; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
