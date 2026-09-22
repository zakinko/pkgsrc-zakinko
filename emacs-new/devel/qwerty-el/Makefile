# $NetBSD$

DISTNAME=	qwerty-1.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}qwerty-el-1.1
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/5b/
EXTRACT_SUFX=	.tar.gz
# an old library that Gentoo keeps on its own mirror; upstream is gone

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://groups.google.com/group/gnu.emacs.sources/msg/eab31c752dfdd3a5
COMMENT=	Switch between QWERTY and DVORAK without changing the console keymap
LICENSE=	# XXX GPL-1+

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/qwerty

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/qwerty

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
