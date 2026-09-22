# $NetBSD$

DISTNAME=	macrostep-geiser-0.2.0.20210717
PKGNAME=	${EMACS_PKGNAME_PREFIX}macrostep-geiser-el-0.2.0.20210717
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=nbfalcon/}
GITHUB_PROJECT=	macrostep-geiser
GITHUB_TAG=	f6a2d5bb96ade4f23df557649af87ebd0cc45125
WRKSRC=		${WRKDIR}/macrostep-geiser-f6a2d5bb96ade4f23df557649af87ebd0cc45125

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/nbfalcon/macrostep-geiser/
COMMENT=	Emacs macrostep back-end powered by geiser
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}geiser-el-[0-9]*:../../devel/geiser-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}macrostep-el-[0-9]*:../../devel/macrostep-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/macrostep-geiser

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/geiser -L ${EMACS_LISPPREFIX}/macrostep -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/macrostep-geiser
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/macrostep-geiser; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
