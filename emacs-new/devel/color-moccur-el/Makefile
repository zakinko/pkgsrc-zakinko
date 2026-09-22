# $NetBSD$

DISTNAME=	color-moccur-2.73
PKGNAME=	${EMACS_PKGNAME_PREFIX}color-moccur-el-2.73
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~ulm/distfiles/
EXTRACT_SUFX=	.el.xz
# upstream is gone; Gentoo keeps the file on its developers' mirror
WRKSRC=		${WRKDIR}
USE_TOOLS+=	xz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://www.bookshelf.jp/
COMMENT=	Major mode for color moccur
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/color-moccur

# a single compressed file, which pkgsrc's extract does not unpack
do-extract:
	xz -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/color-moccur.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/color-moccur
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/color-moccur; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
