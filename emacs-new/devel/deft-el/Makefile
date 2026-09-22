# $NetBSD$

DISTNAME=	deft-08.20210707
PKGNAME=	${EMACS_PKGNAME_PREFIX}deft-el-08.20210707
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=jrblevin/}
GITHUB_PROJECT=	deft
GITHUB_TAG=	28be94d89bff2e1c7edef7244d7c5ba0636b1296
WRKSRC=		${WRKDIR}/deft-28be94d89bff2e1c7edef7244d7c5ba0636b1296

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/jrblevin/deft/
COMMENT=	Quickly browse, filter and edit directories of plain text notes
LICENSE=	modified-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/deft

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/deft

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
