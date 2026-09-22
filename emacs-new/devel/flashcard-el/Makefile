# $NetBSD$

DISTNAME=	flashcard-2.3.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}flashcard-el-2.3.3
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/05/
EXTRACT_SUFX=	.tar.bz2
# an old library that Gentoo keeps on its own mirror; upstream is gone

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/FlashCard
COMMENT=	Emacs Lisp package for drilling on questions and answers
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/flashcard

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/flashcard
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/flashcard; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
