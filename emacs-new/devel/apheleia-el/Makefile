# $NetBSD$

DISTNAME=	apheleia-4.6.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}apheleia-el-4.6.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=radian-software/}
GITHUB_PROJECT=	apheleia
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/radian-software/apheleia/
COMMENT=	Reformat GNU Emacs buffers stably without moving point
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/apheleia

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/apheleia

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
