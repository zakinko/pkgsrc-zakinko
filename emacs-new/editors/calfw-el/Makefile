# $NetBSD$

DISTNAME=	calfw-2.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}calfw-el-2.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=kiwanami/}
GITHUB_PROJECT=	emacs-calfw
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/emacs-calfw-2.0

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/kiwanami/emacs-calfw/
COMMENT=	calendar framework for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/calfw

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

# calfw-howm.el needs misc/howm, which pulls in ruby through migemo;
# it is installed as source only, for those who have howm
do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile calfw.el calfw-cal.el calfw-compat.el calfw-ical.el calfw-org.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/calfw
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/calfw; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
