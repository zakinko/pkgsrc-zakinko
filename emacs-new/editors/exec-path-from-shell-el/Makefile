# $NetBSD$

DISTNAME=	exec-path-from-shell-2.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}exec-path-from-shell-el-2.3
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=purcell/}
GITHUB_PROJECT=	exec-path-from-shell
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/purcell/exec-path-from-shell/
COMMENT=	Ensure environment variables inside Emacs are the same as in shell
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/exec-path-from-shell

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/exec-path-from-shell

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
