# $NetBSD$

DISTNAME=	moccur-edit-2.16
PKGNAME=	${EMACS_PKGNAME_PREFIX}moccur-edit-el-2.16
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~ulm/distfiles/
EXTRACT_SUFX=	.el.bz2
# upstream is gone; Gentoo keeps the file on its developers' mirror
WRKSRC=		${WRKDIR}
USE_TOOLS+=	bzip2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://www.bookshelf.jp/
COMMENT=	An improved interface to color-moccur for editing
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}color-moccur-el-[0-9]*:../../devel/color-moccur-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/moccur-edit

# a single compressed file, which pkgsrc's extract does not unpack
do-extract:
	bzip2 -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/moccur-edit.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/color-moccur -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/moccur-edit
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/moccur-edit; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
