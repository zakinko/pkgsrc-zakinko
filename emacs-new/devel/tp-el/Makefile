# $NetBSD$

DISTNAME=	tp.el-0.9
PKGNAME=	${EMACS_PKGNAME_PREFIX}tp-el-0.9
CATEGORIES=	devel
MASTER_SITES=	https://codeberg.org/martianh/tp.el/archive/
DISTFILES=	${PKGVERSION_NOREV}${EXTRACT_SUFX}
DIST_SUBDIR=	${DISTNAME}
WRKSRC=		${WRKDIR}/tp.el

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://codeberg.org/martianh/tp.el/
COMMENT=	Utilities to create transient menus for POSTing to an API for GNU Emac
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-editors/emacs-
DEPENDS+=	${EMACS_PKGNAME_PREFIX}transient-el-[0-9]*:../../devel/transient-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/tp

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/tp

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
