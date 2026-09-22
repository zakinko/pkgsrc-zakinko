# $NetBSD$

DISTNAME=	swift-mode-10.0.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}swift-mode-10.0.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=swift-emacs/}
GITHUB_PROJECT=	swift-mode
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/swift-emacs/swift-mode/
COMMENT=	Emacs support for Apple's Swift programming language
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/swift-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/swift-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
