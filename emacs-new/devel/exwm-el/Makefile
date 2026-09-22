# $NetBSD$

DISTNAME=	exwm-0.35
PKGNAME=	${EMACS_PKGNAME_PREFIX}exwm-el-0.35
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacs-exwm/}
GITHUB_PROJECT=	exwm
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/emacs-exwm/exwm/
COMMENT=	Emacs X Window Manager
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}xelb-el-[0-9]*:../../devel/xelb-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/exwm

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/xelb -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/exwm

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
