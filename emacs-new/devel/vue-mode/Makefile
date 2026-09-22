# $NetBSD$

DISTNAME=	vue-mode-0.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}vue-mode-0.4
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=AdamNiederer/}
GITHUB_PROJECT=	vue-mode
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/AdamNiederer/vue-mode/
COMMENT=	Major Emacs mode for vue component based on mmm-mode
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}edit-indirect-el-[0-9]*:../../devel/edit-indirect-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}mmm-mode-[0-9]*:../../devel/mmm-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ssass-mode-[0-9]*:../../devel/ssass-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}vue-html-mode-[0-9]*:../../devel/vue-html-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/vue-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/edit-indirect -L ${EMACS_LISPPREFIX}/mmm-mode -L ${EMACS_LISPPREFIX}/ssass-mode -L ${EMACS_LISPPREFIX}/vue-html-mode -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/vue-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
