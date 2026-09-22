# $NetBSD$

DISTNAME=	slime-2.31
PKGNAME=	${EMACS_PKGNAME_PREFIX}slime-el-2.31
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=slime/}
GITHUB_PROJECT=	slime
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://slime.common-lisp.dev/
COMMENT=	SLIME, the Superior Lisp Interaction Mode (Extended)
LICENSE=	public-domain

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-lisp/asdf

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/slime ${EMACS_LISPPREFIX}/slime/contrib

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L contrib -f batch-byte-compile *.el contrib/*.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/slime
	cd ${WRKSRC} && ${INSTALL_DATA} contrib/*.el contrib/*.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/slime/contrib

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
