# $NetBSD$

DISTNAME=	all-the-icons-ibuffer-1.3.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}all-the-icons-ibuffer-el-1.3.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=seagle0128/}
GITHUB_PROJECT=	all-the-icons-ibuffer
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/seagle0128/all-the-icons-ibuffer/
COMMENT=	Display all-the-icons icons for all buffers in Emacs' ibuffer
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}all-the-icons-el-[0-9]*:../../devel/all-the-icons-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/all-the-icons-ibuffer

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/all-the-icons -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/all-the-icons-ibuffer

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
