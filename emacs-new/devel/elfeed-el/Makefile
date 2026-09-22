# $NetBSD$

DISTNAME=	elfeed-4.2.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}elfeed-el-4.2.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacs-elfeed/}
GITHUB_PROJECT=	elfeed
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/emacs-elfeed/elfeed/
COMMENT=	Emacs web feeds client
LICENSE=	unlicense

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	curl-[0-9]*:../../www/curl
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/elfeed

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/elfeed

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
