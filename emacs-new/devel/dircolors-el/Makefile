# $NetBSD$

DISTNAME=	dircolors-1.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}dircolors-el-1.0
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/2b/
EXTRACT_SUFX=	.tar.gz
# an old library that Gentoo keeps on its own mirror; upstream is gone

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://lfs.irisa.fr/~pad/rawaccess.query/hacks/dircolors.el
COMMENT=	Provide the same facility of ls --color inside Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/dircolors

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/dircolors

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
