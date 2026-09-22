# $NetBSD$

DISTNAME=	bongo-1.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}bongo-el-1.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=dbrock/}
GITHUB_PROJECT=	bongo
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/Bongo
COMMENT=	Buffer-oriented media player for Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}volume-el-[0-9]*:../../editors/volume-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/bongo

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/volume -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/bongo
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/bongo; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
