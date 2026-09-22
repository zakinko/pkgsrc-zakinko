# $NetBSD$

DISTNAME=	chess-2.0.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}chess-el-2.0.5
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~ulm/distfiles/
EXTRACT_SUFX=	.tar.xz
# upstream is gone; Gentoo keeps the file on its developers' mirror

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://elpa.gnu.org/packages/chess.html
COMMENT=	chess client and library for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on games-board/crafty
# XXX Gentoo also depends on games-board/fruit
# XXX Gentoo also depends on games-board/gnuchess
# XXX Gentoo also depends on games-board/phalanx
# XXX Gentoo also depends on games-board/sjeng
# XXX Gentoo also depends on games-board/stockfish

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/chess

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/chess
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/chess; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
