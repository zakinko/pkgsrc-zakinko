# $NetBSD$

DISTNAME=	closql-2.4.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}closql-el-2.4.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=magit/}
GITHUB_PROJECT=	closql
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/magit/closql/
COMMENT=	Store EIEIO objects using EmacSQL
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}cond-let-el-[0-9]*:../../devel/cond-let-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}emacsql-el-[0-9]*:../../devel/emacsql-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}llama-el-[0-9]*:../../devel/llama-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/closql

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/emacsql -L ${EMACS_LISPPREFIX}/llama -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/closql
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/closql; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
