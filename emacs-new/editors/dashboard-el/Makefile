# $NetBSD$

DISTNAME=	dashboard-1.8.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}dashboard-el-1.8.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacs-dashboard/}
GITHUB_PROJECT=	dashboard
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/emacs-dashboard/emacs-dashboard/
COMMENT=	Extensible Emacs dashboard, with sections like bookmarks, agenda and m
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/dashboard
USE_TOOLS+=	pax

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/dashboard
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/dashboard; done
	cd ${WRKSRC}/. && ${PAX} -rw banners ${DESTDIR}${EMACS_LISPPREFIX}/dashboard

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
