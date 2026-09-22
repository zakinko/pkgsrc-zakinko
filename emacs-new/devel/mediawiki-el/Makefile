# $NetBSD$

DISTNAME=	mediawiki-2.3.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}mediawiki-el-2.3.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=hexmode/}
GITHUB_PROJECT=	mediawiki-el
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/mediawiki-el-2.3.1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/hexmode/mediawiki-el
COMMENT=	MediaWiki client for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/mediawiki

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/mediawiki

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
