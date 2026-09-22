# $NetBSD$

DISTNAME=	epc-0.1.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}epc-el-0.1.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=kiwanami/}
GITHUB_PROJECT=	emacs-epc
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/emacs-epc-0.1.1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/kiwanami/emacs-epc/
COMMENT=	RPC stack for Emacs Lisp
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ctable-el-[0-9]*:../../devel/ctable-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}deferred-el-[0-9]*:../../devel/deferred-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/epc

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/ctable -L ${EMACS_LISPPREFIX}/deferred -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/epc

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
