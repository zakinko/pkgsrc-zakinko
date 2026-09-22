# $NetBSD$

DISTNAME=	plz-0.9.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}plz-el-0.9.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=alphapapa/}
GITHUB_PROJECT=	plz.el
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/plz.el-0.9.1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/alphapapa/plz.el/
COMMENT=	HTTP library with curl backend for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	curl-[0-9]*:../../www/curl

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/plz

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/plz
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/plz; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
