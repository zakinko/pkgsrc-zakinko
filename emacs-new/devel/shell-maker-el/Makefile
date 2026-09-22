# $NetBSD$

DISTNAME=	shell-maker-0.97.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}shell-maker-el-0.97.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=xenodium/}
GITHUB_PROJECT=	shell-maker
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/xenodium/shell-maker/
COMMENT=	Interaction mode for making comint shells for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-editors/emacs-

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/shell-maker

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/shell-maker

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
