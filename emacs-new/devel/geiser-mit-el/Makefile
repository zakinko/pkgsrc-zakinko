# $NetBSD$

DISTNAME=	mit-0.15
PKGNAME=	${EMACS_PKGNAME_PREFIX}geiser-mit-el-0.15
CATEGORIES=	devel
MASTER_SITES=	https://gitlab.com/emacs-geiser/mit/-/archive/${PKGVERSION_NOREV}/
EXTRACT_SUFX=	.tar.gz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/emacs-geiser/mit/
COMMENT=	MIT/GNU Scheme's implementation of the Geiser protocols
LICENSE=	modified-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-scheme/mit-scheme
DEPENDS+=	${EMACS_PKGNAME_PREFIX}geiser-el-[0-9]*:../../devel/geiser-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/geiser-mit

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/geiser -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/geiser-mit

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
