# $NetBSD$

DISTNAME=	git-timemachine-4.13
PKGNAME=	${EMACS_PKGNAME_PREFIX}git-timemachine-el-4.13
CATEGORIES=	devel
MASTER_SITES=	https://codeberg.org/pidu/git-timemachine/archive/
DISTFILES=	${PKGVERSION_NOREV}${EXTRACT_SUFX}
DIST_SUBDIR=	${DISTNAME}
WRKSRC=		${WRKDIR}/git-timemachine

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://codeberg.org/pidu/git-timemachine/
COMMENT=	Step through historic versions of git controlled files in GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/git-timemachine

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/git-timemachine

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
