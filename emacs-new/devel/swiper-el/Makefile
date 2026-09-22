# $NetBSD$

DISTNAME=	swiper-0.15.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}swiper-el-0.15.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=abo-abo/}
GITHUB_PROJECT=	swiper
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/abo-abo/swiper/
COMMENT=	Alternative to isearch that uses ivy to show overview of all matches
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ivy-el-[0-9]*:../../editors/ivy-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/swiper

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/ivy -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/swiper

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
