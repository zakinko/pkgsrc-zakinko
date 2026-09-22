# $NetBSD$

DISTNAME=	erlang-mode-28.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}erlang-mode-28.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=erlang/}
GITHUB_PROJECT=	otp
GITHUB_TAG=	OTP-28.3
WRKSRC=		${WRKDIR}/otp-OTP-28.3/lib/tools/emacs

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.erlang.org/
COMMENT=	major mode for editing Erlang
LICENSE=	apache-2.0

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-lang/erlang

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/erlang-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/erlang-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/erlang-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
