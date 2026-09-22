# $NetBSD$

DISTNAME=	icicles-2018.10.15.23738
PKGNAME=	${EMACS_PKGNAME_PREFIX}icicles-el-2018.10.15.23738
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacsmirror/}
GITHUB_PROJECT=	icicles
GITHUB_TAG=	9e9c37d2a54771c635d00d1fe171cef5eab4d95d
WRKSRC=		${WRKDIR}/icicles-9e9c37d2a54771c635d00d1fe171cef5eab4d95d

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/Icicles
COMMENT=	Minibuffer input completion and cycling
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}hexrgb-el-[0-9]*:../../devel/hexrgb-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/icicles

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/hexrgb -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/icicles
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/icicles; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
