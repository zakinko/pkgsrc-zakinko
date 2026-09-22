# $NetBSD$

DISTNAME=	avy-embark-collect-1.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}avy-embark-collect-el-1.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=oantolin/}
GITHUB_PROJECT=	embark
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/embark-1.2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/oantolin/embark/
COMMENT=	Use avy to jump to Embark Collect entries
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}avy-el-[0-9]*:../../editors/avy-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}embark-el-[0-9]*:../../devel/embark-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/avy-embark-collect

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/avy -L ${EMACS_LISPPREFIX}/embark -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/avy-embark-collect
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/avy-embark-collect; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
