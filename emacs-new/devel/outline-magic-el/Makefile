# $NetBSD$

DISTNAME=	outline-magic-0.9
PKGNAME=	${EMACS_PKGNAME_PREFIX}outline-magic-el-0.9
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/7b/
EXTRACT_SUFX=	.el.bz2
# an old library that Gentoo keeps on its own mirror; upstream is gone
WRKSRC=		${WRKDIR}
USE_TOOLS+=	bzip2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/tj64/outline-magic
COMMENT=	Outline mode extensions for Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/outline-magic

# a single compressed file; pkgsrc's extract would leave it as outline-magic-0.9.el
do-extract:
	bzip2 -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/outline-magic.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/outline-magic
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/outline-magic; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
