# $NetBSD$

DISTNAME=	erefactor-0.7.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}erefactor-el-0.7.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=mhayashi1120/}
GITHUB_PROJECT=	Emacs-erefactor
GITHUB_TAG=	bfe27a1b8c7cac0fe054e76113e941efa3775fe8
WRKSRC=		${WRKDIR}/Emacs-erefactor-bfe27a1b8c7cac0fe054e76113e941efa3775fe8

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/mhayashi1120/Emacs-erefactor/
COMMENT=	Emacs-Lisp refactoring utilities
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/erefactor

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/erefactor

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
