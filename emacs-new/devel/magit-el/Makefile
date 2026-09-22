# $NetBSD$

DISTNAME=	magit-4.7.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}magit-el-4.7.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=magit/}
GITHUB_PROJECT=	magit
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/magit-4.7.0/lisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://magit.vc/
COMMENT=	Git porcelain inside Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}cond-let-el-[0-9]*:../../devel/cond-let-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}llama-el-[0-9]*:../../devel/llama-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}transient-el-[0-9]*:../../devel/transient-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}with-editor-el-[0-9]*:../../devel/with-editor-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/magit

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/with-editor -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/magit
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/magit; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
