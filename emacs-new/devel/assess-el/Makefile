# $NetBSD$

DISTNAME=	assess-0.7
PKGNAME=	${EMACS_PKGNAME_PREFIX}assess-el-0.7
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=phillord/}
GITHUB_PROJECT=	assess
GITHUB_TAG=	cadeb24a5d8261fad4bdfdc09e7d571cc395a6ca
WRKSRC=		${WRKDIR}/assess-cadeb24a5d8261fad4bdfdc09e7d571cc395a6ca

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/phillord/assess/
COMMENT=	Test support functions for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}m-buffer-el-[0-9]*:../../devel/m-buffer-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/assess

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/m-buffer -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/assess

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
