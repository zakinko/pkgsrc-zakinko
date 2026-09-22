# $NetBSD$

DISTNAME=	god-mode-2.19.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}god-mode-2.19.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacsorphanage/}
GITHUB_PROJECT=	god-mode
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/emacsorphanage/god-mode/
COMMENT=	Minor mode for God-like command entering in GNU Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/god-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/god-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
