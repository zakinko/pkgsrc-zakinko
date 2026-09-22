# $NetBSD$

DISTNAME=	treemacs-all-the-icons-3.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}treemacs-all-the-icons-el-3.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=Alexander-Miller/}
GITHUB_PROJECT=	treemacs
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/treemacs-3.2/src/extra

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/Alexander-Miller/treemacs/
COMMENT=	GNU Emacs all-the-icons integration for treemacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}all-the-icons-el-[0-9]*:../../devel/all-the-icons-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}treemacs-el-[0-9]*:../../editors/treemacs-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/treemacs-all-the-icons

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/all-the-icons -L ${EMACS_LISPPREFIX}/treemacs -L ${EMACS_LISPPREFIX}/ace-window -L ${EMACS_LISPPREFIX}/avy -L ${EMACS_LISPPREFIX}/cfrs -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/posframe -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/ht -L ${EMACS_LISPPREFIX}/hydra -L ${EMACS_LISPPREFIX}/lv -L ${EMACS_LISPPREFIX}/pfuture -f batch-byte-compile treemacs-all-the-icons.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} treemacs-all-the-icons.el ${DESTDIR}${EMACS_LISPPREFIX}/treemacs-all-the-icons
	cd ${WRKSRC} && for f in treemacs-all-the-icons.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/treemacs-all-the-icons; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
