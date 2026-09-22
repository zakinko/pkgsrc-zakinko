# $NetBSD$

DISTNAME=	sumibi-0.7.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}sumibi-el-0.7.4
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_OSDN:=sumibi/26504/}
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/05/
EXTRACT_SUFX=	.tar.gz
WRKSRC=		${WRKDIR}/${DISTNAME}/client/elisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://sumibi.org/sumibi/sumibi.html
COMMENT=	Statistical Japanese input method using the Internet as a large corpus
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/sumibi

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/sumibi
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/sumibi; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
