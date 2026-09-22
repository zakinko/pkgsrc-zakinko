# $NetBSD$

DISTNAME=	orderless-1.7
PKGNAME=	${EMACS_PKGNAME_PREFIX}orderless-el-1.7
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=oantolin/}
GITHUB_PROJECT=	orderless
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/oantolin/orderless/
COMMENT=	Completion style that matches multiple regexps in any order
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/orderless

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/orderless

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
