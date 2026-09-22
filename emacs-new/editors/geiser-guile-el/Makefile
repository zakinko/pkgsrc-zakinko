# $NetBSD$

DISTNAME=	geiser-guile-0.28.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}geiser-guile-el-0.28.5
CATEGORIES=	editors
MASTER_SITES=	https://elpa.nongnu.org/nongnu/
EXTRACT_SUFX=	.tar

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/emacs-geiser/guile/
COMMENT=	Guile's implementation of the Geiser protocols
LICENSE=	modified-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	guile30-[0-9]*:../../lang/guile30
DEPENDS+=	${EMACS_PKGNAME_PREFIX}geiser-el-[0-9]*:../../devel/geiser-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}transient-el-[0-9]*:../../devel/transient-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/geiser-guile
USE_TOOLS+=	pax

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/geiser -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/geiser-guile
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/geiser-guile; done
	cd ${WRKSRC}/. && ${PAX} -rw src ${DESTDIR}${EMACS_LISPPREFIX}/geiser-guile

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
