# $NetBSD$

DISTNAME=	company-coq-1.0.1.20220314
PKGNAME=	${EMACS_PKGNAME_PREFIX}company-coq-el-1.0.1.20220314
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=cpitclaudel/}
GITHUB_PROJECT=	company-coq
GITHUB_TAG=	a6e349e0131f676a885bd14c908fd26054b2df42
WRKSRC=		${WRKDIR}/company-coq-a6e349e0131f676a885bd14c908fd26054b2df42

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/cpitclaudel/company-coq/
COMMENT=	Collection of extensions for Proof General's Coq mode
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}company-math-el-[0-9]*:../../devel/company-math-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}company-mode-[0-9]*:../../devel/company-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}proofgeneral-el-[0-9]*:../../devel/proofgeneral-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}yasnippet-el-[0-9]*:../../devel/yasnippet-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/company-coq

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/company-math -L ${EMACS_LISPPREFIX}/company-mode -L ${EMACS_LISPPREFIX}/posframe -L ${EMACS_LISPPREFIX}/math-symbol-lists -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/proofgeneral -L ${EMACS_LISPPREFIX}/yasnippet -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/company-coq
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/company-coq; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
