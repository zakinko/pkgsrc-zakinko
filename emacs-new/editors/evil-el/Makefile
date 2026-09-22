# $NetBSD$

DISTNAME=	evil-1.14.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}evil-el-1.14.2
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacs-evil/}
GITHUB_PROJECT=	evil
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/emacs-evil/evil
COMMENT=	Extensible vi layer for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}undo-tree-el-[0-9]*:../../editors/undo-tree-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/evil

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/undo-tree -L ${EMACS_LISPPREFIX}/queue -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/evil

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
