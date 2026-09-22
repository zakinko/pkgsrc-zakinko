# $NetBSD$

DISTNAME=	key-chord-0.8.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}key-chord-el-0.8.2
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacsorphanage/}
GITHUB_PROJECT=	key-chord
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/emacsorphanage/key-chord/
COMMENT=	Map pairs of simultaneously pressed keys to commands
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/key-chord

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/key-chord
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/key-chord; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
