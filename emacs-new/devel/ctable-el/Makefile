# $NetBSD$

DISTNAME=	ctable-0.1.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}ctable-el-0.1.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=kiwanami/}
GITHUB_PROJECT=	emacs-ctable
GITHUB_TAG=	04dbcddeba1da1f39e885bc0d36240ff37d829e9
WRKSRC=		${WRKDIR}/emacs-ctable-04dbcddeba1da1f39e885bc0d36240ff37d829e9

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/kiwanami/emacs-ctable/
COMMENT=	Table Component for Emacs Lisp
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ctable

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/ctable

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
