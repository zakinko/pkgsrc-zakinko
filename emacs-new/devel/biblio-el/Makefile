# $NetBSD$

DISTNAME=	biblio-0.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}biblio-el-0.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=cpitclaudel/}
GITHUB_PROJECT=	biblio.el
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/biblio.el-0.3

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/cpitclaudel/biblio.el/
COMMENT=	Browse and import bibliographic references with Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/biblio

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/biblio

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
