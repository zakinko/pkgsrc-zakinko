# $NetBSD$

DISTNAME=	shut-up-0.3.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}shut-up-el-0.3.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=cask/}
GITHUB_PROJECT=	shut-up
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/cask/shut-up/
COMMENT=	Reduce Emacs output of messages
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/shut-up

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/shut-up

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
