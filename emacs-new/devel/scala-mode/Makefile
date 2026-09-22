# $NetBSD$

DISTNAME=	scala-tool-support-2.10.7
PKGNAME=	${EMACS_PKGNAME_PREFIX}scala-mode-2.10.7
CATEGORIES=	devel
MASTER_SITES=	https://www.scala-lang.org/files/archive/
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/4d/
EXTRACT_SUFX=	.tgz
WRKSRC=		${WRKDIR}/${DISTNAME}/scala-emacs-mode

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.scala-lang.org/
COMMENT=	Scala mode for Emacs
LICENSE=	modified-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/scala-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/scala-mode
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/scala-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
