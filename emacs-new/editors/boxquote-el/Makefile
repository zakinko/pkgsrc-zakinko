# $NetBSD$

DISTNAME=	boxquote-2.4.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}boxquote-el-2.4.1
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=davep/}
GITHUB_PROJECT=	boxquote.el
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/boxquote.el-2.4.1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://www.davep.org/emacs/
COMMENT=	Quote text with a semi-box
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/boxquote

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/boxquote

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
