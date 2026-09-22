# $NetBSD$

DISTNAME=	org-roam-2.3.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}org-roam-el-2.3.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=org-roam/}
GITHUB_PROJECT=	org-roam
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/org-roam/org-roam
COMMENT=	Rudimentary Roam replica with Org-mode
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}buttercup-el-[0-9]*:../../devel/buttercup-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}emacsql-el-[0-9]*:../../devel/emacsql-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}magit-el-[0-9]*:../../devel/magit-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/org-roam

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/buttercup -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/emacsql -L ${EMACS_LISPPREFIX}/magit -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/with-editor -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/org-roam
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/org-roam; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
