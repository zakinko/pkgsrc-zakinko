# $NetBSD$

DISTNAME=	multi-term-1.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}multi-term-el-1.4
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~mjo/distfiles/
EXTRACT_SUFX=	.el.xz
# upstream is gone; Gentoo keeps the file on its developers' mirror
WRKSRC=		${WRKDIR}
USE_TOOLS+=	xz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/MultiTerm
COMMENT=	Manage multiple terminal buffers in Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/multi-term

# a single compressed file, which pkgsrc's extract does not unpack
do-extract:
	xz -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/multi-term.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/multi-term
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/multi-term; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
