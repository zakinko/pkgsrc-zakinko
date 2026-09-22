# $NetBSD$

DISTNAME=	all-the-icons-5.0.0.20230316
PKGNAME=	${EMACS_PKGNAME_PREFIX}all-the-icons-el-5.0.0.20230316
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=domtronn/}
GITHUB_PROJECT=	all-the-icons.el
GITHUB_TAG=	d922aff57ac8308d3ed067f9151cc76d342855f2
WRKSRC=		${WRKDIR}/all-the-icons.el-d922aff57ac8308d3ed067f9151cc76d342855f2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/domtronn/all-the-icons.el/
COMMENT=	Various icon fonts propertized for Emacs
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/all-the-icons ${EMACS_LISPPREFIX}/all-the-icons/data

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L data -f batch-byte-compile *.el data/*.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/all-the-icons
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/all-the-icons; done
	cd ${WRKSRC} && ${INSTALL_DATA} data/*.el ${DESTDIR}${EMACS_LISPPREFIX}/all-the-icons/data
	cd ${WRKSRC} && for f in data/*.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/all-the-icons/data; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
