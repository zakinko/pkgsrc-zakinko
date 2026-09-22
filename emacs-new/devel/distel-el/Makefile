# $NetBSD$

DISTNAME=	distel-4.1.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}distel-el-4.1.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=massemanet/}
GITHUB_PROJECT=	distel
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/distel-4.1.1/elisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://massemanet.github.io/distel/
COMMENT=	Distributed Emacs Lisp for Erlang
LICENSE=	modified-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-lang/erlang
DEPENDS+=	${EMACS_PKGNAME_PREFIX}erlang-mode-[0-9]*:../../devel/erlang-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/distel

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/erlang-mode -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/distel
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/distel; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
