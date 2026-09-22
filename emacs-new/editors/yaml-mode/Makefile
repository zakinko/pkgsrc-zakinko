# $NetBSD$

DISTNAME=	yaml-mode-0.0.16
PKGNAME=	${EMACS_PKGNAME_PREFIX}yaml-mode-0.0.16
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=yoshiki/}
GITHUB_PROJECT=	yaml-mode
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/yoshiki/yaml-mode/
COMMENT=	A major mode for GNU Emacs for editing YAML files
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/yaml-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/yaml-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
