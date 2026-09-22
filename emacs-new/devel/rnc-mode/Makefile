# $NetBSD$

DISTNAME=	rnc-mode-1.0.6
PKGNAME=	${EMACS_PKGNAME_PREFIX}rnc-mode-1.0.6
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=TreeRex/}
GITHUB_PROJECT=	rnc-mode
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/TreeRex/rnc-mode
COMMENT=	An Emacs mode for editing Relax NG compact schema files
LICENSE=	modified-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/rnc-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/rnc-mode
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/rnc-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
