# $NetBSD$

DISTNAME=	demap.el-v1.4.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}demap-el-1.4.0
CATEGORIES=	devel
MASTER_SITES=	https://gitlab.com/sawyerjgardner/demap.el/-/archive/v${PKGVERSION_NOREV}/
EXTRACT_SUFX=	.tar.gz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/sawyerjgardner/demap.el/
COMMENT=	Detachable minimap for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/demap

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/demap
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/demap; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
