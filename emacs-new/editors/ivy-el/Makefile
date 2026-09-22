# $NetBSD$

DISTNAME=	ivy-0.15.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}ivy-el-0.15.1
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=abo-abo/}
GITHUB_PROJECT=	swiper
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/swiper-0.15.1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/abo-abo/swiper/
COMMENT=	Generic completion mechanism for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ivy

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

# Ivy proper, as Gentoo splits it: swiper, counsel and the ivy-* extensions
# in the same tarball are not built
do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile colir.el ivy.el ivy-overlay.el ivy-faces.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} colir.el ivy.el ivy-overlay.el ivy-faces.el colir.elc ivy.elc ivy-overlay.elc ivy-faces.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/ivy

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
