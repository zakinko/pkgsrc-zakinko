# $NetBSD$

DISTNAME=	systemd-mode-1.6
PKGNAME=	${EMACS_PKGNAME_PREFIX}systemd-mode-1.6
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=holomorph/}
GITHUB_PROJECT=	systemd-mode
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/holomorph/systemd-mode/
COMMENT=	Major mode for editing systemd units in GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/systemd-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/systemd-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/systemd-mode; done
	cd ${WRKSRC} && ${INSTALL_DATA} *-directives.txt ${DESTDIR}${EMACS_LISPPREFIX}/systemd-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
