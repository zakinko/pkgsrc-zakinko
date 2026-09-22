# $NetBSD$

DISTNAME=	string-inflection-1.0.16
PKGNAME=	${EMACS_PKGNAME_PREFIX}string-inflection-el-1.0.16
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=akicho8/}
GITHUB_PROJECT=	string-inflection
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/akicho8/string-inflection/
COMMENT=	Convert symbol names between different naming conventions
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/string-inflection

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/string-inflection

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
