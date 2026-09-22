# $NetBSD$

DISTNAME=	vertico-2.14
PKGNAME=	${EMACS_PKGNAME_PREFIX}vertico-el-2.14
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=minad/}
GITHUB_PROJECT=	vertico
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/minad/vertico/
COMMENT=	Vertical interactive completion
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/vertico

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/vertico

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
