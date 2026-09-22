# $NetBSD$

DISTNAME=	boogie-friends-0.1.20220922
PKGNAME=	${EMACS_PKGNAME_PREFIX}boogie-friends-el-0.1.20220922
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=boogie-org/}
GITHUB_PROJECT=	boogie-friends
GITHUB_TAG=	8d1bafab5dffc3c63324b5306503943e67497ddc
WRKSRC=		${WRKDIR}/boogie-friends-8d1bafab5dffc3c63324b5306503943e67497ddc/emacs

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/boogie-org/boogie-friends/
COMMENT=	Emacs tools for interacting with Boogie, Dafny and Z3 (SMT2)
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}company-mode-[0-9]*:../../devel/company-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}flycheck-mode-[0-9]*:../../textproc/flycheck-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}yasnippet-el-[0-9]*:../../devel/yasnippet-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/boogie-friends

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/company-mode -L ${EMACS_LISPPREFIX}/posframe -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/yasnippet -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/boogie-friends
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/boogie-friends; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
