# $NetBSD$

DISTNAME=	poke-3.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}poke-el-3.2
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~arsen/
EXTRACT_SUFX=	.tar.xz
# upstream is gone; Gentoo keeps the file on its developers' mirror

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://elpa.gnu.org/packages/poke.html
COMMENT=	Emacs meets GNU poke!
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-util/poke-3.0
DEPENDS+=	${EMACS_PKGNAME_PREFIX}poke-mode-[0-9]*:../../devel/poke-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/poke

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/poke-mode -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/poke

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
