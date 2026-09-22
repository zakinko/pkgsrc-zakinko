# $NetBSD$

DISTNAME=	request-0.3.3.20220318
PKGNAME=	${EMACS_PKGNAME_PREFIX}request-el-0.3.3.20220318
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=tkf/}
GITHUB_PROJECT=	emacs-request
GITHUB_TAG=	c769cf33f2ac0a1a9798b508935c4b260e856ab5
WRKSRC=		${WRKDIR}/emacs-request-c769cf33f2ac0a1a9798b508935c4b260e856ab5

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/tkf/emacs-request/
COMMENT=	Compatible layer for URL request
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}deferred-el-[0-9]*:../../devel/deferred-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/request

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/deferred -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/request

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
