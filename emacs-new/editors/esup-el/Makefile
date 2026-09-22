# $NetBSD$

DISTNAME=	esup-0.7.1.20220203
PKGNAME=	${EMACS_PKGNAME_PREFIX}esup-el-0.7.1.20220203
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=jschaf/}
GITHUB_PROJECT=	esup
GITHUB_TAG=	4b49c8d599d4cc0fbf994e9e54a9c78e5ab62a5f
WRKSRC=		${WRKDIR}/esup-4b49c8d599d4cc0fbf994e9e54a9c78e5ab62a5f

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/jschaf/esup/
COMMENT=	Benchmark Emacs Startup time without ever leaving it
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/esup

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/s -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/esup
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/esup; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
