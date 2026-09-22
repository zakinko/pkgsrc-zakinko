# $NetBSD$

DISTNAME=	edit-indirect-0.1.13
PKGNAME=	${EMACS_PKGNAME_PREFIX}edit-indirect-el-0.1.13
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=Fanael/}
GITHUB_PROJECT=	edit-indirect
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/Fanael/edit-indirect/
COMMENT=	Edit regions in separate Emacs buffers
LICENSE=	2-clause-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/edit-indirect

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/edit-indirect

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
