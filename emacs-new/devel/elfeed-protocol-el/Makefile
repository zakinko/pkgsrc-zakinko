# $NetBSD$

DISTNAME=	elfeed-protocol-1.0.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}elfeed-protocol-el-1.0.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=fasheng/}
GITHUB_PROJECT=	elfeed-protocol
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/fasheng/elfeed-protocol/
COMMENT=	Provide extra news client subscription protocols for elfeed
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}elfeed-el-[0-9]*:../../devel/elfeed-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/elfeed-protocol

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/elfeed -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/elfeed-protocol

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
