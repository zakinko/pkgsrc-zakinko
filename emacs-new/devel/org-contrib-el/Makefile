# $NetBSD$

DISTNAME=	org-contrib-release_0.8
PKGNAME=	${EMACS_PKGNAME_PREFIX}org-contrib-el-0.8
CATEGORIES=	devel
MASTER_SITES=	https://git.sr.ht/~bzg/org-contrib/archive/
DISTFILES=	release_0.8${EXTRACT_SUFX}
DIST_SUBDIR=	${DISTNAME}
WRKSRC=		${WRKDIR}/${DISTNAME}/lisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://orgmode.org/
COMMENT=	Contributed packages to Org
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}org-mode-[0-9]*:../../devel/org-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/org-contrib

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/org-mode -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/org-contrib
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/org-contrib; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
