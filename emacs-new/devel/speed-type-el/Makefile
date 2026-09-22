# $NetBSD$

DISTNAME=	speed-type-20230206
PKGNAME=	${EMACS_PKGNAME_PREFIX}speed-type-el-20230206
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=dakra/}
GITHUB_PROJECT=	speed-type
GITHUB_TAG=	4f8553632d71e827b4da6e091143779d2ad970a8
WRKSRC=		${WRKDIR}/speed-type-4f8553632d71e827b4da6e091143779d2ad970a8

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/dakra/speed-type
COMMENT=	Practice touch and speed typing
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/speed-type

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/speed-type
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/speed-type; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
