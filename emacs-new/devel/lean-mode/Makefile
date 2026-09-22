# $NetBSD$

DISTNAME=	lean-mode-0.20230611
PKGNAME=	${EMACS_PKGNAME_PREFIX}lean-mode-0.20230611
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=leanprover/}
GITHUB_PROJECT=	lean3-mode
GITHUB_TAG=	99d6a34dc5b12f6e996e9217fa9f6fe4a6af037a
WRKSRC=		${WRKDIR}/lean3-mode-99d6a34dc5b12f6e996e9217fa9f6fe4a6af037a

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/leanprover/lean-mode/
COMMENT=	Emacs mode for the Lean 3 theorem prover
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}flycheck-mode-[0-9]*:../../textproc/flycheck-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/lean-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/lean-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/lean-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
