# $NetBSD$

DISTNAME=	graphql-0.1.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}graphql-el-0.1.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=vermiculus/}
GITHUB_PROJECT=	graphql.el
GITHUB_TAG=	67237f284f2dfb94f3cfba672ff64a37e1cb860f
WRKSRC=		${WRKDIR}/graphql.el-67237f284f2dfb94f3cfba672ff64a37e1cb860f

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/vermiculus/graphql.el/
COMMENT=	GraphQL utilities
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/graphql

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/graphql

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
