# $NetBSD$

DISTNAME=	forge-0.6.9
PKGNAME=	${EMACS_PKGNAME_PREFIX}forge-el-0.6.9
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=magit/}
GITHUB_PROJECT=	forge
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/forge-0.6.9/lisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://docs.magit.vc/forge/
COMMENT=	Work with Git forges from the comfort of Magit
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}closql-el-[0-9]*:../../devel/closql-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}cond-let-el-[0-9]*:../../devel/cond-let-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}emacsql-el-[0-9]*:../../devel/emacsql-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ghub-el-[0-9]*:../../devel/ghub-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}llama-el-[0-9]*:../../devel/llama-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}magit-el-[0-9]*:../../devel/magit-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}markdown-mode-[0-9]*:../../textproc/markdown-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}transient-el-[0-9]*:../../devel/transient-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}yaml-el-[0-9]*:../../devel/yaml-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/forge

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/closql -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/emacsql -L ${EMACS_LISPPREFIX}/llama -L ${EMACS_LISPPREFIX}/ghub -L ${EMACS_LISPPREFIX}/treepy -L ${EMACS_LISPPREFIX}/magit -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/with-editor -L ${EMACS_LISPPREFIX}/yaml -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/forge
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/forge; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
