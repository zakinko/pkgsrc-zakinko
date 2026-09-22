# $NetBSD$

DISTNAME=	org-superstar-mode-1.6.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}org-superstar-mode-1.6.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=integral-dw/}
GITHUB_PROJECT=	org-superstar-mode
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/integral-dw/org-superstar-mode/
COMMENT=	Prettify headings and plain lists in Org mode (use UTF8 bullets)
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/org-superstar-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/org-superstar-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
