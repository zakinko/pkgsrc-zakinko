# $NetBSD$

DISTNAME=	elm-mode-0.22.0.20250401
PKGNAME=	${EMACS_PKGNAME_PREFIX}elm-mode-0.22.0.20250401
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=jcollard/}
GITHUB_PROJECT=	elm-mode
GITHUB_TAG=	90b72cd2c9bc4506f531bcdcd73fa2530d9f4f7c
WRKSRC=		${WRKDIR}/elm-mode-90b72cd2c9bc4506f531bcdcd73fa2530d9f4f7c

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/jcollard/elm-mode/
COMMENT=	Major mode for the Elm programming language
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}reformatter-el-[0-9]*:../../devel/reformatter-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/elm-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/reformatter -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/elm-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
