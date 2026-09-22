# $NetBSD$

DISTNAME=	telega-0.8.660.20260806
PKGNAME=	${EMACS_PKGNAME_PREFIX}telega-el-0.8.660.20260806
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=zevlg/}
GITHUB_PROJECT=	telega.el
GITHUB_TAG=	c7273cce799d60b6c8bb470cfa26ed267324ff02
WRKSRC=		${WRKDIR}/telega.el-c7273cce799d60b6c8bb470cfa26ed267324ff02

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://zevlg.github.io/telega.el/
COMMENT=	Full-featured unofficial GNU Emacs client for Telegram
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-editors/emacs-
# XXX Gentoo also depends on net-libs/tdlib
DEPENDS+=	${EMACS_PKGNAME_PREFIX}all-the-icons-el-[0-9]*:../../devel/all-the-icons-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}company-mode-[0-9]*:../../devel/company-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dashboard-el-[0-9]*:../../editors/dashboard-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}transient-el-[0-9]*:../../devel/transient-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}visual-fill-column-el-[0-9]*:../../devel/visual-fill-column-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/telega

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/all-the-icons -L ${EMACS_LISPPREFIX}/company-mode -L ${EMACS_LISPPREFIX}/posframe -L ${EMACS_LISPPREFIX}/dashboard -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -L ${EMACS_LISPPREFIX}/visual-fill-column -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/telega
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/telega; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
