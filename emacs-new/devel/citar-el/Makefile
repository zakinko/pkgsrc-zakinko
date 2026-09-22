# $NetBSD$

DISTNAME=	citar-1.4.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}citar-el-1.4.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacs-citar/}
GITHUB_PROJECT=	citar
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/emacs-citar/citar/
COMMENT=	Emacs package to quickly find and act on bibliographic references
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}citeproc-el-el-[0-9]*:../../devel/citeproc-el-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}parsebib-el-[0-9]*:../../devel/parsebib-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/citar

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/citeproc-el -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/parsebib -L ${EMACS_LISPPREFIX}/queue -L ${EMACS_LISPPREFIX}/string-inflection -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/citar

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
