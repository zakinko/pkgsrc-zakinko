# $NetBSD$

DISTNAME=	rfcview-0.13
PKGNAME=	${EMACS_PKGNAME_PREFIX}rfcview-el-0.13
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~ulm/distfiles/
EXTRACT_SUFX=	.el.xz
# upstream is gone; Gentoo keeps the file on its developers' mirror
WRKSRC=		${WRKDIR}
USE_TOOLS+=	xz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://www.loveshack.ukfsn.org/emacs/
COMMENT=	An Emacs mode that reformats IETF RFCs for display
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/rfcview

# a single compressed file, which pkgsrc's extract does not unpack
do-extract:
	xz -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/rfcview.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/rfcview
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/rfcview; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
