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
LICENSE=	gnu-gpl-v1 OR gnu-gpl-v2 OR gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/qwerty

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/qwerty
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/qwerty; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
