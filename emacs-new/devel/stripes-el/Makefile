# $NetBSD$

DISTNAME=	stripes-el-0.3.1.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}stripes-el-0.3.1.1
CATEGORIES=	devel
MASTER_SITES=	https://gitlab.com/stepnem/stripes-el/-/archive/${PKGVERSION_NOREV}/
EXTRACT_SUFX=	.tar.bz2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/StripesMode
COMMENT=	An Emacs mode that alternates the background color of lines
LICENSE=	public-domain

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/stripes

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/stripes

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
