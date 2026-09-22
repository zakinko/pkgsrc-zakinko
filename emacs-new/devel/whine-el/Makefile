# $NetBSD$

DISTNAME=	whine-20231020
PKGNAME=	${EMACS_PKGNAME_PREFIX}whine-el-20231020
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~ulm/distfiles/
EXTRACT_SUFX=	.el.xz
# upstream is gone; Gentoo keeps the file on its developers' mirror
WRKSRC=		${WRKDIR}
USE_TOOLS+=	xz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/Whine
COMMENT=	Complaint generator for GNU Emacs
LICENSE=	cc0-1.0-universal

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/whine

# a single compressed file, which pkgsrc's extract does not unpack
do-extract:
	xz -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/whine.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/whine
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/whine; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
