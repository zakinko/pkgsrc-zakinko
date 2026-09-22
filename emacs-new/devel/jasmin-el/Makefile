# $NetBSD$

DISTNAME=	jasmin-1.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}jasmin-el-1.2
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/93/
EXTRACT_SUFX=	.tar.gz
# an old library that Gentoo keeps on its own mirror; upstream is gone

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.neilvandyke.org/jasmin-emacs/
COMMENT=	Emacs major mode for editing Jasmin Java bytecode assembler files
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/jasmin

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/jasmin
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/jasmin; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
