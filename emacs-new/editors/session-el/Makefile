# $NetBSD$

DISTNAME=	session-2.4b
PKGNAME=	${EMACS_PKGNAME_PREFIX}session-el-2.4b
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_SOURCEFORGE:=emacs-session/}
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/7a/
EXTRACT_SUFX=	.tar.gz
WRKSRC=		${WRKDIR}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://emacs-session.sourceforge.net/
COMMENT=	When you start Emacs, Session restores various variables from your las
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/session

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/session
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/session; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
