# $NetBSD$

DISTNAME=	tuareg-mode-3.1.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}tuareg-mode-3.1.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ocaml/}
GITHUB_PROJECT=	tuareg
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/tuareg-3.1.0

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://forge.ocamlcore.org/projects/tuareg/
COMMENT=	An Objective Caml/Camllight mode for Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/tuareg-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/tuareg-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
