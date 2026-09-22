# $NetBSD$

DISTNAME=	binclock-1.12
PKGNAME=	${EMACS_PKGNAME_PREFIX}binclock-el-1.12
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=davep/}
GITHUB_PROJECT=	binclock.el
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/binclock.el-1.12

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://www.davep.org/emacs/
COMMENT=	Display the current time using a binary clock
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/binclock

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/binclock

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
