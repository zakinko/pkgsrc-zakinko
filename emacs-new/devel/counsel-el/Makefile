# $NetBSD$

DISTNAME=	counsel-0.15.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}counsel-el-0.15.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=abo-abo/}
GITHUB_PROJECT=	swiper
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/swiper-0.15.1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/abo-abo/swiper/
COMMENT=	Versions of common Emacs commands customized to make the best use of i
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ivy-el-[0-9]*:../../editors/ivy-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}swiper-el-[0-9]*:../../devel/swiper-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/counsel

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/ivy -L ${EMACS_LISPPREFIX}/swiper -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/counsel
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/counsel; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
