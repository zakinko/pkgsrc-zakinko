# $NetBSD$

DISTNAME=	shell-split-string-0.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}shell-split-string-el-0.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=10sr/}
GITHUB_PROJECT=	shell-split-string-el
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/shell-split-string-el-0.1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/10sr/shell-split-string-el/
COMMENT=	Split Strings Using Shell-Like Syntax
LICENSE=	unlicense

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/shell-split-string

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/shell-split-string

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
