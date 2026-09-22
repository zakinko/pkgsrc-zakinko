# $NetBSD$

DISTNAME=	log4e-0.4.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}log4e-el-0.4.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=aki2o/}
GITHUB_PROJECT=	log4e
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/aki2o/log4e/
COMMENT=	Logging framework for GNU Emacs Lisp
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/log4e

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/log4e

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
