# $NetBSD$

DISTNAME=	engrave-faces-0.3.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}engrave-faces-el-0.3.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=tecosaur/}
GITHUB_PROJECT=	engrave-faces
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/tecosaur/engrave-faces/
COMMENT=	Convert font-lock faces to other formats
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/engrave-faces

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/engrave-faces

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
