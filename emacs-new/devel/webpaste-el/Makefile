# $NetBSD$

DISTNAME=	webpaste-3.2.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}webpaste-el-3.2.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=etu/}
GITHUB_PROJECT=	webpaste.el
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/webpaste.el-3.2.2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/etu/webpaste.el/
COMMENT=	Paste parts of buffers to several pastebin-like services from Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}request-el-[0-9]*:../../devel/request-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/webpaste

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/request -L ${EMACS_LISPPREFIX}/deferred -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/webpaste
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/webpaste; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
