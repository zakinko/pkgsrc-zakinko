# $NetBSD$

DISTNAME=	parsebib-6.7
PKGNAME=	${EMACS_PKGNAME_PREFIX}parsebib-el-6.7
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=joostkremers/}
GITHUB_PROJECT=	parsebib
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/joostkremers/parsebib/
COMMENT=	Emacs Lisp library for reading .bib files
LICENSE=	modified-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/parsebib

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/parsebib

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
