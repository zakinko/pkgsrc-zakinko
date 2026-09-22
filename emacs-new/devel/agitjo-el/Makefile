# $NetBSD$

DISTNAME=	agitjo-v2.0.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}agitjo-el-2.0.0
CATEGORIES=	devel
MASTER_SITES=	https://codeberg.org/halvin/agitjo/archive/
DISTFILES=	v${PKGVERSION_NOREV}${EXTRACT_SUFX}
DIST_SUBDIR=	${DISTNAME}
WRKSRC=		${WRKDIR}/agitjo

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://codeberg.org/halvin/agitjo/
COMMENT=	Manage Forgejo PRs with AGit-Flow in Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}magit-el-[0-9]*:../../devel/magit-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}markdown-mode-[0-9]*:../../textproc/markdown-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}transient-el-[0-9]*:../../devel/transient-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/agitjo

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/magit -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/with-editor -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/agitjo
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/agitjo; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
