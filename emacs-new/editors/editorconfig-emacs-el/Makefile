# $NetBSD$

DISTNAME=	editorconfig-emacs-0.11.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}editorconfig-emacs-el-0.11.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=editorconfig/}
GITHUB_PROJECT=	editorconfig-emacs
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/editorconfig/editorconfig-emacs
COMMENT=	EditorConfig plugin for emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/editorconfig-emacs

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/editorconfig-emacs

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
