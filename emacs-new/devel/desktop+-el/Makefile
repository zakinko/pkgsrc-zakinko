# $NetBSD$

DISTNAME=	desktop+-0.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}desktop+-el-0.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ffevotte/}
GITHUB_PROJECT=	desktop-plus
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/desktop-plus-0.2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ffevotte/desktop-plus
COMMENT=	desktop+ extends standard desktop module
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/desktop+

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/desktop+

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
