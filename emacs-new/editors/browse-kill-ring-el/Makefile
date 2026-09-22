# $NetBSD$

DISTNAME=	browse-kill-ring-2.1.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}browse-kill-ring-el-2.1.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=browse-kill-ring/}
GITHUB_PROJECT=	browse-kill-ring
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/BrowseKillRing
COMMENT=	An improved interface to kill-ring
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/browse-kill-ring

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/browse-kill-ring

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
