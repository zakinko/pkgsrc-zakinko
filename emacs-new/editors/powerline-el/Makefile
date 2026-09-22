# $NetBSD$

DISTNAME=	powerline-2.5.20221110
PKGNAME=	${EMACS_PKGNAME_PREFIX}powerline-el-2.5.20221110
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=milkypostman/}
GITHUB_PROJECT=	powerline
GITHUB_TAG=	c35c35bdf5ce2d992882c1f06f0f078058870d4a
WRKSRC=		${WRKDIR}/powerline-c35c35bdf5ce2d992882c1f06f0f078058870d4a

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/milkypostman/powerline/
COMMENT=	GNU Emacs version of the Vim powerline
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/powerline

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/powerline

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
