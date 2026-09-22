# $NetBSD$

DISTNAME=	denote-4.2.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}denote-el-4.2.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=protesilaos/}
GITHUB_PROJECT=	denote
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://protesilaos.com/emacs/denote/
COMMENT=	Simple notes for Emacs with an efficient file-naming scheme
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/denote

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/denote

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
