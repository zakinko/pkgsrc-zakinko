# $NetBSD$

DISTNAME=	filladapt-2.12.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}filladapt-el-2.12.2
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~ulm/distfiles/
EXTRACT_SUFX=	.el.gz
# upstream is gone; Gentoo keeps the file on its developers' mirror
WRKSRC=		${WRKDIR}
USE_TOOLS+=	gzip

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://www.wonderworks.com/
COMMENT=	Filladapt enhances the behavior of Emacs' fill functions
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/filladapt

# a single compressed file, which pkgsrc's extract does not unpack
do-extract:
	gzip -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/filladapt.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/filladapt
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/filladapt; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
