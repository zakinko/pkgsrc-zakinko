# $NetBSD$

DISTNAME=	avy-0.5.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}avy-el-0.5.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=abo-abo/}
GITHUB_PROJECT=	avy
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/abo-abo/avy
COMMENT=	Jump to arbitrary positions in visible text and quickly select
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/avy

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/avy

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
