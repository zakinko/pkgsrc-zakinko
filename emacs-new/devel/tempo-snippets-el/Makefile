# $NetBSD$

DISTNAME=	tempo-snippets-0.1.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}tempo-snippets-el-0.1.5
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~ulm/distfiles/
EXTRACT_SUFX=	.el.bz2
# upstream is gone; Gentoo keeps the file on its developers' mirror
WRKSRC=		${WRKDIR}
USE_TOOLS+=	bzip2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://nschum.de/src/emacs/tempo-snippets/
COMMENT=	Visual insertion of tempo templates
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/tempo-snippets

# a single compressed file, which pkgsrc's extract does not unpack
do-extract:
	bzip2 -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/tempo-snippets.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/tempo-snippets
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/tempo-snippets; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
