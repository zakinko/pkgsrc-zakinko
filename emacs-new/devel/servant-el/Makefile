# $NetBSD$

DISTNAME=	servant-0.3.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}servant-el-0.3.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=cask/}
GITHUB_PROJECT=	servant
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/cask/servant/
COMMENT=	ELPA server written in Emacs Lisp
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ansi-el-[0-9]*:../../devel/ansi-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}commander-el-[0-9]*:../../devel/commander-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}epl-el-[0-9]*:../../devel/epl-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}shut-up-el-[0-9]*:../../devel/shut-up-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}web-server-el-[0-9]*:../../devel/web-server-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/servant

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/ansi -L ${EMACS_LISPPREFIX}/commander -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/epl -L ${EMACS_LISPPREFIX}/shut-up -L ${EMACS_LISPPREFIX}/web-server -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/servant

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
