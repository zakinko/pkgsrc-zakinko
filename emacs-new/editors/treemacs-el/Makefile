# $NetBSD$

DISTNAME=	treemacs-3.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}treemacs-el-3.2
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=Alexander-Miller/}
GITHUB_PROJECT=	treemacs
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/treemacs-3.2/src/elisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/Alexander-Miller/treemacs/
COMMENT=	Tree style project file explorer
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-editors/emacs-
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ace-window-el-[0-9]*:../../editors/ace-window-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}cfrs-el-[0-9]*:../../devel/cfrs-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ht-el-[0-9]*:../../devel/ht-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}hydra-el-[0-9]*:../../editors/hydra-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}pfuture-el-[0-9]*:../../devel/pfuture-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/treemacs
USE_TOOLS+=	pax

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/ace-window -L ${EMACS_LISPPREFIX}/avy -L ${EMACS_LISPPREFIX}/cfrs -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/posframe -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/ht -L ${EMACS_LISPPREFIX}/hydra -L ${EMACS_LISPPREFIX}/lv -L ${EMACS_LISPPREFIX}/pfuture -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/treemacs
	cd ${WRKSRC}/../.. && ${PAX} -rw icons ${DESTDIR}${EMACS_LISPPREFIX}/treemacs
	${MKDIR} ${DESTDIR}${EMACS_LISPPREFIX}/treemacs/src
	cd ${WRKSRC}/.. && ${PAX} -rw scripts ${DESTDIR}${EMACS_LISPPREFIX}/treemacs/src

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
