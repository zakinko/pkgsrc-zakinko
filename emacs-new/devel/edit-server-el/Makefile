# $NetBSD$

DISTNAME=	edit-server-1.16
PKGNAME=	${EMACS_PKGNAME_PREFIX}edit-server-el-1.16
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=stsquad/}
GITHUB_PROJECT=	emacs_chrome
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/emacs_chrome-1.16/servers

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/stsquad/emacs_chrome
COMMENT=	Service edit requests from a web browser for editing of textareas
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/edit-server

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/edit-server
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/edit-server; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
