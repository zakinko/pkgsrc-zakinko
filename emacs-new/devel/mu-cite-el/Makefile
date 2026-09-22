# $NetBSD$

DISTNAME=	mu-cite-202011031127
PKGNAME=	${EMACS_PKGNAME_PREFIX}mu-cite-el-8.1.202011031127
CATEGORIES=	devel
MASTER_SITES=	https://www.jpl.org/elips/mu/snapshots/
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/35/
EXTRACT_SUFX=	.tar.gz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.jpl.org/elips/mu/
COMMENT=	Message citation utilities for emacsen
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}apel-[0-9]*:../../devel/apel
DEPENDS+=	${EMACS_PKGNAME_PREFIX}bbdb-[0-9]*:../../misc/bbdb3
DEPENDS+=	${EMACS_PKGNAME_PREFIX}flim-[0-9]*:../../devel/flim

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/mu-cite

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/apel -L ${EMACS_LISPPREFIX}/bbdb -L ${EMACS_LISPPREFIX}/flim -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/mu-cite
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/mu-cite; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
