# $NetBSD$

DISTNAME=	edit-list-0.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}edit-list-el-0.3
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~ulm/distfiles/
EXTRACT_SUFX=	.el.bz2
# upstream is gone; Gentoo keeps the file on its developers' mirror
WRKSRC=		${WRKDIR}
USE_TOOLS+=	bzip2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://mwolson.org/projects/
COMMENT=	Edit a single list
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/edit-list

# a single compressed file, which pkgsrc's extract does not unpack
do-extract:
	bzip2 -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/edit-list.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/edit-list
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/edit-list; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
