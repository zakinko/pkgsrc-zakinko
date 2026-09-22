# $NetBSD$

DISTNAME=	emacs-websearch-2.1.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs-websearch-el-2.1.0
CATEGORIES=	devel
MASTER_SITES=	https://gitlab.com/xgqt/emacs-websearch/-/archive/${PKGVERSION_NOREV}/
EXTRACT_SUFX=	.tar.bz2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/xgqt/emacs-websearch/
COMMENT=	Query search engines from Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emacs-websearch

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/emacs-websearch

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
