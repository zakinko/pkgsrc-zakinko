# $NetBSD$

DISTNAME=	ocaml-mode-4.05.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}ocaml-mode-4.05.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ocaml/}
GITHUB_PROJECT=	ocaml
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/ocaml-4.05.0/emacs

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://ocaml.org/
COMMENT=	Emacs mode for OCaml
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ocaml-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/ocaml-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
