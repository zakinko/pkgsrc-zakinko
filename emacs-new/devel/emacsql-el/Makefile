# $NetBSD$

DISTNAME=	emacsql-4.4.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacsql-el-4.4.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=magit/}
GITHUB_PROJECT=	emacsql
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/magit/emacsql/
COMMENT=	A high-level Emacs Lisp RDBMS front-end
LICENSE=	unlicense

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-db/postgresql

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emacsql

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/emacsql

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
